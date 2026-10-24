#!/bin/sh

#-------------------------------------------------------------------------------
# Set up git for current user by:
#
# 1. asking for user details;
# 2. setting global git user;
# 3. setting global git email;
# 4. setting global branch to "main";
# 5. generating an ssh key at "~/.ssh/github";
# 6. adding a "github.com" host that uses the key to "~/.ssh/config"; and
# 7. testing the ssh connection to Github.
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
. ./linshafun/comments-logs.sh
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
# . ./linshafun/host-initialisation.sh
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
# Set the ssh file variables for the Linux user. The key is "~/.ssh/github",
# and "addHostToSshConfig" points the "github.com" host at it.
#-------------------------------------------------------------------------------
SSH_KEY_NAME='github'
SSH_KEY_PATH="$SSH_DIR_PATH/$SSH_KEY_NAME"

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
# Runs a command as "$SUDO_USER", with "$HOME" set to their home directory.
# Takes one or more mandatory arguments:
#
# 1. "$@" – the command and its arguments, e.g. "git config --list".
#
# Returns the command's exit status.
#
# N.B.
# As the script is run as "sudo", "git" and "ssh" would otherwise read and
# write root's "~/.gitconfig" and "~/.ssh". "sudo -H" sets "$HOME" for the
# user. Each argument is passed as given, so values with spaces, e.g. a git
# username of "Joe Bloggs", stay as one argument.
#-------------------------------------------------------------------------------
runAsSudoUser () {
  : "${1:?}"

  sudo -H -u "$SUDO_USER" "$@"
}

#-------------------------------------------------------------------------------
# Set global git username and email, using values from getGitDetails. Returns 1
# with an error if either can't be set.
#-------------------------------------------------------------------------------
setGitDetails () {
  printComment "Setting global git username to $GIT_USERNAME."

  if ! runAsSudoUser git config --global user.name "$GIT_USERNAME"; then
    printComment --error 'Failed to set the global git username.'

    return 1
  fi

  printComment "Setting global git email to $GIT_EMAIL"

  if ! runAsSudoUser git config --global user.email "$GIT_EMAIL"; then
    printComment --error 'Failed to set the global git email.'

    return 1
  fi
}

#-------------------------------------------------------------------------------
# Set global default branch to "main". Returns 1 with an error if it can't be
# set.
#-------------------------------------------------------------------------------
setGitDefaultBranch () {
  printComment 'Setting global default branch to main.'

  if ! runAsSudoUser git config --global init.defaultBranch main; then
    printComment --error 'Failed to set the global default branch.'

    return 1
  fi
}

#-------------------------------------------------------------------------------
# Get the user to copy public ssh key to Github account.
#-------------------------------------------------------------------------------
getUserToAddKey () {
  printComment --warning "You must add the contents of ~/.ssh/$SSH_KEY_NAME.pub to your Github account via:"
  printComment --warning 'Settings > Access > SSH and GPG keys'
  printComment --warning 'You will likely need to open a separate command line session to copy the contents. We will wait while you go add the key…'
}

#-------------------------------------------------------------------------------
# Check if the user has added the key to their Github account. Block progress
# until they have added it.
#-------------------------------------------------------------------------------
checkUserAddedKey () {
  sleep 5
  promptForUserInput 'Have you added the ssh key to your account (y/n)?'
  KEY_ADDED_YN=false
  if getUserInputYN; then KEY_ADDED_YN=true; fi

  if [ "$KEY_ADDED_YN" = true ]; then
    printComment 'Key added to Github – we will know later if you fibbed…'
  else
    getUserToAddKey
    checkUserAddedKey
  fi
}

#-------------------------------------------------------------------------------
# List the global git configuration of "$SUDO_USER".
#-------------------------------------------------------------------------------
listGitConfig () {
  printComment 'Listing git configuration.'
  printSeparator
  runAsSudoUser git config --global --list
  printSeparator
}

#-------------------------------------------------------------------------------
# Test the ssh connection to Github as "$SUDO_USER", so their ssh config and
# key are used. The exit status isn't checked; the user reads the output
# instead.
#-------------------------------------------------------------------------------
testGitSsh () {
  printComment 'Testing ssh connection to git:'
  printSeparator
  runAsSudoUser ssh -T git@github.com
  printSeparator
  printComment 'If you saw a success message, the key was added successfully. If you saw an error about permissions, when this script exits you can try:'
  printComment 'ssh -vT git@github.com'
  printComment --warning 'If the above still does not work, you fibbed about adding your key…'
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script. Returns 1 as soon as a step fails.
# The linshafun functions print the error.
#-------------------------------------------------------------------------------
mainScript () {
  getGitDetails
  setGitDetails || return 1
  setGitDefaultBranch || return 1

  createDirectory "$SSH_DIR_PATH" '700' "$SUDO_USER" || return 1
  checkForAndCreateSshConfig || return 1

  generateSshKey "$SSH_KEY_PATH" "$GIT_EMAIL" || return 1
  addHostToSshConfig "github.com" "" "" "" "$SSH_KEY_NAME" || return 1

  getUserToAddKey
  checkUserAddedKey
  listGitConfig
  testGitSsh
}

#-------------------------------------------------------------------------------
# Run the script. If "mainScript" fails, the script exits with 1 before
# "finaliseScript", so the step isn't recorded as done in the setup config file
# and can be run again.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"

if ! mainScript; then
  printScriptExiting --changes
  exit 1
fi

finaliseScript "$CONFIG_KEY"
