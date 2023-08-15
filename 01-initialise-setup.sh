#!/bin/sh

#-------------------------------------------------------------------------------
# Initialises the setup by:
#
# 1. updating and upgrading packages; and
# 2. creating a config file in "~/.config/linux-setup/setup.conf"
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
CONFIG_KEY='initialisedSetup'

#-------------------------------------------------------------------------------
# Removes the setup config file within "$SETUP_CONF", based on the users input.
#
# If the user requests to delete, the file is deleted.
#
# If the user doesn't request to delete, the file is left alone.
#
# Any input other than "y", "Y", "n' or "N" will re-run this function.
#-------------------------------------------------------------------------------
removeCurrentSetupConfig () {
  echoComment 'Do you want to remove the existing setup config file in:'
  echoComment "$SETUP_CONF_DIR (y/n)?"
  echoComment 'N.B. This cannot be undone, and we wont ask for confirmation.'
  read -r SETUP_CONF_YN

  if [ "$SETUP_CONF_YN" = 'y' -o "$SETUP_CONF_YN" = 'Y' ]; then
    echoComment 'Deleting setup config file.'
    rm "$SETUP_CONF"
    echoComment 'Setup config file deleted.'
  elif [ "$SETUP_CONF_YN" = 'n' -o "$SETUP_CONF_YN" = 'N' ]; then
    echoComment 'Leaving setup config file intact.'
  else
    echoComment 'You must answer y or n.'
    removeCurrentSetupConfig
  fi
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  updateUpgrade
  checkForSetupConfigDir
  checkForSetupConfigFile
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"