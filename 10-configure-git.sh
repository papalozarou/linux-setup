#!/bin/sh

#-------------------------------------------------------------------------------
# Set up git for current user by:
#
# 1. asking for user details;
# 2. setting global git user;
# 3. setting global git email;
# 4. setting global branch to "main";
# 5. generating an ssh key;
# 6. adding the ssh key to the ssh agent; and
# 7. generating an ssh config file.
#
# N.B.
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported shared variables.
#-------------------------------------------------------------------------------
. ./linshafun/linshafun.var

#-------------------------------------------------------------------------------
# Imported project specific variables.
#-------------------------------------------------------------------------------
. ./linux-setup.var

#-------------------------------------------------------------------------------
# Imported shared functions.
#-------------------------------------------------------------------------------
. ./linshafun/comments.sh
# . ./linshafun/docker-env-variables.sh
# . ./linshafun/docker-images.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
# . ./linshafun/host-information.sh
# . ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
. ./linshafun/ssh-keys.sh
. ./linshafun/text.sh
. ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredGit'
SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" "lower")"

#-------------------------------------------------------------------------------
# Set the ssh file variables for the Linux user.
#-------------------------------------------------------------------------------
SSH_CONF="$SSH_DIR/config"
SSH_KEY="$SSH_DIR/github"

#-------------------------------------------------------------------------------
# Request user details to use in global git settings and when generating ssh key
# for Github.
#-------------------------------------------------------------------------------
getGitDetails () {
  promptForUserInput 'What global git username do you want to use with git?'
  GIT_USERNAME="$(getUserInput)"
  promptForUserInput 'What global git email do you want to use with git?'
  GIT_EMAIL="$(getUserInput)"
}

#-------------------------------------------------------------------------------
# Set global git username and email, using values from getGitDetails.
#
# N.B.
# As the script is run as "sudo" it is necessary to execute the git commands
# as the "$SUDO_USER", as per:
#
# - https://stackoverflow.com/a/1988255
#-------------------------------------------------------------------------------
setGitDetails () {
  echoComment "Setting global git username to $GIT_USERNAME."
  su -c "git config --global user.name "$GIT_USERNAME"" "$SUDO_USER"

  echoComment "Setting global git email to $GIT_EMAIL"
  su -c "git config --global user.email "$GIT_EMAIL"" "$SUDO_USER"
}

#-------------------------------------------------------------------------------
# Set global default branch to "main".
# 
# N.B.
# As the script is run as "sudo" it is necessary to execute the git commands
# as the "$SUDO_USER", as per:
#
# - https://stackoverflow.com/a/1988255
#-------------------------------------------------------------------------------
setGitDefaultBranch () {
  echoComment 'Setting global default branch to main.'
  su -c "git config --global init.defaultBranch main" "$SUDO_USER"
}

#-------------------------------------------------------------------------------
# Start the "ssh-agent" and add the newly generated key to it.
#-------------------------------------------------------------------------------
addSshKeytoAgent () {
  echoComment 'Adding the generated key to the ssh-agent.'
  echoSeparator
  eval "$(ssh-agent -s)"
  ssh-add "$SSH_KEY"
  echoSeparator
  echoComment 'Key added to agent.'
}

#-------------------------------------------------------------------------------
# Generate an ssh config file.
#-------------------------------------------------------------------------------
generateSshConfig () {
  echoComment 'Generating ssh config file at:'
  echoComment "$SSH_CONF"
  cat <<EOF > "$SSH_CONF"
Host github.com
  Hostname github.com
  IdentityFile ~/.ssh/github
  IdentitiesOnly yes
EOF
  echoComment 'Config file generated.'
}

#-------------------------------------------------------------------------------
# Get the user to copy public ssh key to Github account.
#-------------------------------------------------------------------------------
getUserToAddKey () {
  echoComment 'You must add the contents of ~/.ssh/github.pub to your Github'
  echoComment 'account via:'
  echoComment 'Settings > Access > SSH and GPG keys'
  echoComment 'You will likely need to open a separate command line session to'
  echoComment 'copy the contents. We will wait a while you go add the key…'
}

#-------------------------------------------------------------------------------
# Check if the user has added the key to their Github account. Block progress
# until they have added it.
#
# N.B.
# As we are trying to be POSIX compliant, we are using "-eq" and "-o" within
# single brackets as per:
#
# - https://queirozf.com/entries/posix-shell-tests-and-conditionals-examples-and-reference
#-------------------------------------------------------------------------------
checkUserAddedKey () {
  sleep 5
  promptForUserInput 'Have you added the ssh key to your account (y/n)?'
  KEY_ADDED="$(getUserInputYN)"

  if [ "$KEY_ADDED" = true ]; then
    echoComment 'Key added to Github – we will know later if you fibbed…'
  else
    echoComment 'You must add your key to Github proceed. Please add it now via:'
    echoSeparator
    echoComment 'github.com > Settings > Access > SSH and GPG keys'
    echoSeparator
    echoComment 'You will likely need to open a separate command line session to'
    echoComment 'copy the contents of the key.'
    checkUserAddedKey
  fi
}

#-------------------------------------------------------------------------------
# List git configuration.
#-------------------------------------------------------------------------------
listGitConfig () {
  echoComment 'Listing git configuration.'
  echoSeparator
  git config --list
  echoSeparator
}

#-------------------------------------------------------------------------------
# Test ssh connection.
#-------------------------------------------------------------------------------
testGitSsh () {
  echoComment 'Testing ssh connection to git:'
  echoSeparator
  ssh -T git@github.com
  echoSeparator
  echoComment 'If you saw a success message, you are good to go. If you saw an' 
  echoComment 'error about permissions, when this script exits you can try:'
  echoComment 'ssh -T git@github.com'
  echoComment 'If that still does not work, you fibbed about adding your key…'
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  getGitDetails
  setGitDetails
  setGitDefaultBranch
  generateSshKey "$SSH_KEY" "$GIT_EMAIL"
  setOwner "$SUDO_USER" "$SSH_KEY"
  setOwner "$SUDO_USER" "$SSH_KEY.pub"
  addSshKeytoAgent
  generateSshConfig
  setPermissions 600 "$SSH_CONF"
  setOwner "$SUDO_USER" "$SSH_CONF"
  getUserToAddKey
  checkUserAddedKey
  listGitConfig
  testGitSsh
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"