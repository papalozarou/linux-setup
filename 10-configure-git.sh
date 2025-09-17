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
# . ./linshafun/linshafun-docker.var

#-------------------------------------------------------------------------------
# Imported project specific variables.
#-------------------------------------------------------------------------------
. ./linux-setup.var

#-------------------------------------------------------------------------------
# Imported shared functions.
#-------------------------------------------------------------------------------
. ./linshafun/comments.sh
# . ./linshafun/crontab.sh
# . ./linshafun/docker-env-variables.sh
# . ./linshafun/docker-images.sh
# . ./linshafun/docker-secrets.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/docker-volumes.sh
. ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
# . ./linshafun/host-information.sh
# . ./linshafun/initialisation.sh
# . ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
. ./linshafun/ssh-config.sh
. ./linshafun/ssh-keys.sh
. ./linshafun/text.sh
. ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredGit'
# SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" "lower")"

#-------------------------------------------------------------------------------
# Set the ssh file variables for the Linux user.
#-------------------------------------------------------------------------------
SSH_KEY_PATH="$SSH_DIR_PATH/github"

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
  printComment "Setting global git username to $GIT_USERNAME."
  su -c "git config --global user.name "$GIT_USERNAME"" "$SUDO_USER"

  printComment "Setting global git email to $GIT_EMAIL"
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
  printComment 'Setting global default branch to main.'
  su -c "git config --global init.defaultBranch main" "$SUDO_USER"
}

#-------------------------------------------------------------------------------
# Get the user to copy public ssh key to Github account.
#-------------------------------------------------------------------------------
getUserToAddKey () {
  printComment 'You must add the contents of ~/.ssh/github.pub to your Github account via:' 'warning'
  printComment 'Settings > Access > SSH and GPG keys' 'warning'
  printComment 'You will likely need to open a separate command line session to copy the contents. We will wait a while you go add the key…' 'warning'
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
  KEY_ADDED_YN="$(getUserInputYN)"

  if [ "$KEY_ADDED_YN" = true ]; then
    printComment 'Key added to Github – we will know later if you fibbed…'
  else
    getUserToAddKey
    checkUserAddedKey
  fi
}

#-------------------------------------------------------------------------------
# List git configuration.
#-------------------------------------------------------------------------------
listGitConfig () {
  printComment 'Listing git configuration.'
  printSeparator
  git config --list
  printSeparator
}

#-------------------------------------------------------------------------------
# Test ssh connection.
#-------------------------------------------------------------------------------
testGitSsh () {
  printComment 'Testing ssh connection to git:'
  printSeparator
  ssh -T git@github.com
  printSeparator
  printComment 'If you saw a success message, the key was added successfully. If you saw an error about permissions, when this script exits you can try:'
  printComment 'ssh -T git@github.com'
  printComment 'If the above still does not work, you fibbed about adding your key…' 'warning'
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  getGitDetails
  setGitDetails
  setGitDefaultBranch

  checkForAndCreateSshDir
  checkForAndCreateSshConfig

  generateSshKey "$SSH_KEY_PATH" "$GIT_EMAIL"
  addSshKeytoAgent "$SSH_KEY_PATH"
  addHostToSshConfig "github" "github.com"

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