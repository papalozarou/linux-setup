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
# Returns 1 as soon as a step fails. The linshafun functions print the error.
#
# N.B.
# We also write the ssh key filename to the config file.
#
# "checkForAndCreateAuthorizedKeys" creates "authorized_keys" with mode "600"
# and "$SUDO_USER" as owner if it doesn't exist. Otherwise the root-run
# "addKeyToAuthorizedKeys" would create it owned by root.
#-------------------------------------------------------------------------------
mainScript () {
  if [ -f "$EXISTING_SSH_KEY_PATH" ]; then
    confirmPrivateSshKeyCopied "$EXISTING_SSH_KEY_PATH"
  else
    createDirectory "$SSH_DIR_PATH" '700' "$SUDO_USER" || return 1
    checkForAndCreateSshConfig || return 1
    checkForAndCreateAuthorizedKeys || return 1

    getSshKeyDetails
    generateSshKey "$SSH_KEY_PATH" "$SSH_EMAIL" || return 1
    addKeyToAuthorizedKeys "$SSH_KEY_PATH" || return 1
    printPrivateKeyUsage "$SSH_KEY_NAME"
    writeSetupConfigOption "sshKeyFile" "$SSH_KEY_NAME" || return 1

    printSeparator
    printComment --warning 'Script finished. Please ensure you copied the private key at:'
    printComment --warning -- "$SSH_KEY_PATH"
    printComment --warning 'Once you have copied the key, run this script again to complete the ssh key setup.'
    printSeparator

    exit 1
  fi
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
