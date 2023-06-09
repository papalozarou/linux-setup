#!/bin/sh

#-------------------------------------------------------------------------------
# Set up an ssh key for remote connections to the server.
#
# N.B.
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY="setupSshKey"

#-------------------------------------------------------------------------------
# Get the name of the ssh key, and set the variable "$SSH_KEY".
#-------------------------------------------------------------------------------
getSshKeyDetails () {
  echoComment 'What do you want to call your ssh key?'
  read -r REMOTE_KEY_NAME
  echoComment 'What email do you want to add to your ssh key?'
  read -r SSH_EMAIL

  SSH_KEY="$SSH_DIR/$REMOTE_KEY_NAME"
}

#-------------------------------------------------------------------------------
# Adds the newly generated public key to the "authorized_keys" file.
#-------------------------------------------------------------------------------
addKeyToAuthorizedKeys () {
  echoComment "Adding public key to $SSH_DIR/authorized_keys."
  cat "$SSH_KEY.pub" >> "$SSH_DIR/authorized_keys"
  echoComment 'Key added.'
}

#-------------------------------------------------------------------------------
# Tell the user to copy the private key to their local machine.
#-------------------------------------------------------------------------------
echoKeyUsage () {
  echoComment "Please copy the private key, $REMOTE_KEY_NAME, to your local"
  echoComment '~/.ssh directory.'
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
# 
# N.B.
# We also write the ssh key filename to the config file.
#-------------------------------------------------------------------------------
mainScript () {
  getSshKeyDetails
  generateSshKey "$SSH_KEY" "$SSH_EMAIL"
  setOwner "$SUDO_USER" "$SSH_KEY"
  setOwner "$SUDO_USER" "$SSH_KEY.pub"
  addKeyToAuthorizedKeys
  echoKeyUsage
  writeSetupConfigOption sshKeyFile "$REMOTE_KEY_NAME"
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"