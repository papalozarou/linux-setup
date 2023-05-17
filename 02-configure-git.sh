#!/bin/sh

#-------------------------------------------------------------------------------
# Set up git for current user by:
#
# 1. asking for user details;
# 2. setting global git user;
# 3. setting global git email;
# 4. setting global branch to `main`;
# 5. generating an ssh key;
# 6. adding the ssh key to the ssh agent; and
# 7. generating an ssh config file.
#
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Set the ssh file variables for the Linux user.
#-------------------------------------------------------------------------------
SSH_CONF=$SSH_DIR/config
SSH_KEY=$SSH_DIR/github

#-------------------------------------------------------------------------------
# Request user details to use in global git settings and when generating ssh key
# for Github.
#-------------------------------------------------------------------------------
getGitDetails () {
  read -p  "$COMMENT_PREFIX"'What global git username do you want to use with git? ' GIT_USERNAME
  read -p  "$COMMENT_PREFIX"'What global git email do you want to use with git? ' GIT_EMAIL
}

#-------------------------------------------------------------------------------
# Set global git username and email, using values from getGitDetails.
#-------------------------------------------------------------------------------
setGitDetails () {
  echo "$COMMENT_PREFIX"'Setting global git username to '"$GIT_USERNAME"'.'
  git config --global user.name $GIT_USERNAME

  echo "$COMMENT_PREFIX"'Setting global git email to '"$GIT_EMAIL"'.'
  git config --global user.email "$GIT_EMAIL"
}

#-------------------------------------------------------------------------------
# Set global default branch to `main`.
#-------------------------------------------------------------------------------
setGitDefaultBranch () {
  echo "$COMMENT_PREFIX"'Setting global default branch to main.'
  git config --global init.defaultBranch main
}

#-------------------------------------------------------------------------------
# Start the `ssh-agent` and add the newly generated key to it.
#-------------------------------------------------------------------------------
addSshKeytoAgent () {
  echo "$COMMENT_PREFIX"'Adding the generated key to the ssh-agent.'
  echo "$COMMENT_SEPARATOR"
  eval "$(ssh-agent -s)"
  ssh-add $SSH_KEY
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'Key added to agent.'
}

#-------------------------------------------------------------------------------
# Generate an ssh config file.
#-------------------------------------------------------------------------------
generateSshConfig () {
  echo "$COMMENT_PREFIX"'Generating ssh config file at ~/.ssh/config.'
  cat <<EOF > $SSH_CONF
Host github.com
  Hostname github.com
  IdentityFile ~/.ssh/github
  IdentitiesOnly yes
EOF
  echo "$COMMENT_PREFIX"'Config file generated.'
}

#-------------------------------------------------------------------------------
# Get the user to copy public ssh key to Github account.
#-------------------------------------------------------------------------------
getUserToAddKey () {
  echo "$COMMENT_PREFIX"'You must add the contents of ~/.ssh/github.pub to your Github account via:'
  echo "$COMMENT_PREFIX"'Settings > Access > SSH and GPG keys'
  echo "$COMMENT_PREFIX"'You will likely need to open a separate command line session to copy the contents.'
  echo "$COMMENT_PREFIX"'We will wait a while you go add the key…'
}

#-------------------------------------------------------------------------------
# Check if the user has added the key to their Github account. Block progress
# until they have added it.
#
# N.B.
# As we are trying to be POSIX compliant, we are using `-eq` and `-o` within
# single brackets as per:
#
# https://queirozf.com/entries/posix-shell-tests-and-conditionals-examples-and-reference
#-------------------------------------------------------------------------------
checkUserAddedKey () {
  sleep 5
  read -p "$COMMENT_PREFIX"'Have you added the ssh key to your account (y/n)? ' KEY_ADDED

  if [ $KEY_ADDED = 'y' -o $KEY_ADDED = 'Y' ]; then
    echo "$COMMENT_PREFIX"'Key added to Github – we will know later if you fibbed…'
  else
    echo "$COMMENT_PREFIX"'You must add your key to Github proceed. Please add it now via:'
    echo "$COMMENT_PREFIX"'Settings > Access > SSH and GPG keys'
    echo "$COMMENT_PREFIX"'You will likely need to open a separate command line session to copy the contents.'
    checkUserAddedKey
  fi
}

#-------------------------------------------------------------------------------
# List git configuration.
#-------------------------------------------------------------------------------
listGitConfig () {
  echo "$COMMENT_PREFIX"'Listing git configuration…'
  echo "$COMMENT_SEPARATOR"
  git config --list
  echo "$COMMENT_SEPARATOR"
}

#-------------------------------------------------------------------------------
# Test ssh connection
#-------------------------------------------------------------------------------
testGitSsh () {
  echo "$COMMENT_PREFIX"'Testing ssh connection to git, which should show a success message.'
  echo "$COMMENT_SEPARATOR"
  ssh -T git@github.com
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'If you saw a success message, you are good to go.'
  echo "$COMMENT_PREFIX"'If you saw an error about permissions when this script exits you can try:'
  echo "$COMMENT_PREFIX"'ssh -T git@github.com'
  echo "$COMMENT_PREFIX"'If that still does not work, you fibbed about adding your key.'
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
getGitDetails
setGitDetails
setGitDefaultBranch
generateSshKey $SSH_KEY $GIT_EMAIL
setOwner $SUDO_USER $SSH_KEY
setOwner $SUDO_USER $SSH_KEY.pub
addSshKeytoAgent
generateSshConfig
setPermissions 600 $SSH_CONF
setOwner $SUDO_USER $SSH_CONF
getUserToAddKey
checkUserAddedKey
listGitConfig
testGitSsh
echoScriptFinished 'setting up git'