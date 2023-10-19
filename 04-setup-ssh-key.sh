#!/bin/sh

#-------------------------------------------------------------------------------
# Set up an ssh key for remote connections to the server.
#
# N.B.
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported variables.
#-------------------------------------------------------------------------------
. ./linshafun/setup.var

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
# . ./linshafun/network.sh
# . ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
. ./linshafun/ssh-keys.sh
# . ./linshafun/text.sh
. ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY="setupSshKey"

#-------------------------------------------------------------------------------
# File variables.
#-------------------------------------------------------------------------------
EXISTING_KEY_NAME="$(readSetupConfigOption "sshKeyFile")"
EXISTING_SSH_KEY="$SSH_DIR/$EXISTING_KEY_NAME"

#-------------------------------------------------------------------------------
# Adds the newly generated public key to the "authorized_keys" file.
#-------------------------------------------------------------------------------
addKeyToAuthorizedKeys () {
  echoComment "Adding public key to $SSH_DIR/authorized_keys."
  cat "$SSH_KEY.pub" >> "$SSH_DIR/authorized_keys"
  echoComment 'Key added.'
}

#-------------------------------------------------------------------------------
# Checks that a user has copied the key after running the script before. If yes,
# remove it, if no or other input direct to copy the key and run this function
# again.
# 
# N.B.
# "promptForUserInput" is not used here as it's a multiline question.
#-------------------------------------------------------------------------------
checkPrivateSshKeyCopied () {
  echoComment "Have you copied the private key, $EXISTING_KEY_NAME, to your"
  echoComment 'local ~/.ssh directory (y/n)?'
  echoNb
  echoComment 'If you answer y and have not copied the key, you will lose'
  echoComment 'access via ssh.'
  KEY_COPIED_YN="$(getUserInput)"

  if [ "$KEY_COPIED_YN" = 'y' -o "$KEY_COPIED_YN" = 'Y' ]; then
    removePrivateSshKey
  elif [ "$KEY_COPIED_YN" = 'n' -o "$KEY_COPIED_YN" = 'N' ]; then
    echoComment "You must copy the private key, $EXISTING_KEY_NAME, to your"
    echoComment 'local ~/.ssh directory.'
    checkPrivateSshKeyCopied
  else
    echoComment 'You must answer y or n.'
    checkPrivateSshKeyCopied
  fi
}

#-------------------------------------------------------------------------------
# Removes the generated private key, once the script has been run.
#-------------------------------------------------------------------------------
removePrivateSshKey () {
  echoComment 'Removing the private key at:'
  echoComment "$EXISTING_SSH_KEY"
  sh -c "rm $EXISTING_SSH_KEY"
  echoComment "Key removed."
}

#-------------------------------------------------------------------------------
# Tell the user to copy the private key to their local machine.
#-------------------------------------------------------------------------------
echoKeyUsage () {
  echoComment "Please copy the private key, $REMOTE_KEY_NAME, to your local"
  echoComment '~/.ssh directory.'
}

#-------------------------------------------------------------------------------
# Get the name of the ssh key, and set the variable "$SSH_KEY".
#-------------------------------------------------------------------------------
getSshKeyDetails () {
  promptForUserInput 'What do you want to call your ssh key?'
  REMOTE_KEY_NAME="$(getUserInput)"
  promptForUserInput 'What email do you want to add to your ssh key?'
  SSH_EMAIL="$(getUserInput)"

  SSH_KEY="$SSH_DIR/$REMOTE_KEY_NAME"
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script, by checking whether the ssh key 
# already exists. If it does exist delete it, if it doesn't exist, create it.
# 
# N.B.
# We also write the ssh key filename to the config file.
#-------------------------------------------------------------------------------
mainScript () {
  if [ -f "$EXISTING_SSH_KEY" ]; then
    checkPrivateSshKeyCopied
  else
    getSshKeyDetails
    generateSshKey "$SSH_KEY" "$SSH_EMAIL"
    setOwner "$SUDO_USER" "$SSH_KEY"
    setOwner "$SUDO_USER" "$SSH_KEY.pub"
    addKeyToAuthorizedKeys
    echoKeyUsage
    writeSetupConfigOption "sshKeyFile" "$REMOTE_KEY_NAME"

    echoSeparator
    echoComment 'Script finished. Please ensure you copied the private key and'
    echoComment 'run this script again.'

    exit 1
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"