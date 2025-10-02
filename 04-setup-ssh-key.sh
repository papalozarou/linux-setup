#!/bin/sh

#-------------------------------------------------------------------------------
# Set up an ssh key for remote connections to the server.
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
# . ./linshafun/text.sh
. ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY="setupSshKey"

#-------------------------------------------------------------------------------
# File variables.
#-------------------------------------------------------------------------------
EXISTING_SSH_KEY_NAME="$(readSetupConfigValue "sshKeyFile")"
EXISTING_SSH_KEY_PATH="$SSH_DIR_PATH/$EXISTING_SSH_KEY_NAME"

#-------------------------------------------------------------------------------
# Executes the main functions of the script, by checking whether the ssh key 
# already exists. If it does exist delete it, if it doesn't exist, create it.
# 
# N.B.
# We also write the ssh key filename to the config file.
#-------------------------------------------------------------------------------
mainScript () {
  if [ -f "$EXISTING_SSH_KEY_PATH" ]; then
    checkPrivateSshKeyCopied "$EXISTING_SSH_KEY_PATH"
  else
    checkForAndCreateSshDir
    checkForAndCreateSshConfig

    getSshKeyDetails
    generateSshKey "$SSH_KEY_PATH" "$SSH_EMAIL"
    addKeyToAuthorizedKeys "$SSH_KEY_PATH"
    printPrivateKeyUsage "$SSH_KEY_NAME"
    writeSetupConfigOption "sshKeyFile" "$SSH_KEY_NAME"

    printSeparator
    printComment 'Script finished. Please ensure you copied the private key at:' 'warning'
    printComment "$SSH_KEY_PATH" 'warning'
    printComment 'Once you have copied the key, run this script again.' 'warning'
    printSeparator

    exit 1
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"