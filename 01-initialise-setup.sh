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
# Creates the setup config directory at "$SETUP_CONF_DIR".
#-------------------------------------------------------------------------------
createSetupDir () {
  echoComment "Creating setup config directory at $SETUP_CONF_DIR."
  mkdir -p "$SETUP_CONF_DIR"

  echoSeparator
  ls -lna "$SETUP_CONF_DIR"
  echoSeparator

  echoComment 'Setup config directory created.'
}

#-------------------------------------------------------------------------------
# Creates the basic setup config file in "$SETUP_CONF_DIR".
#-------------------------------------------------------------------------------
createSetupConfig () {
  echoComment "Creating setup config file in $SETUP_CONF_DIR."

  cat <<EOF > "$SETUP_CONF"
initialisedSetup true
EOF

  echoComment 'Setup config file created.'
}

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
    echoComment "Deleting setup config file in $SETUP_CONF_DIR."
    rm "$SETUP_CONF"
    echoComment 'Setup config file deleted.'
  elif [ "$SETUP_CONF_YN" = 'n' -o "$SETUP_CONF_YN" = 'N' ]; then
    echoComment "Leaving setup config file in $SETUP_CONF_DIR intact."
  else
    echoComment 'You must answer y or n.'
    removeCurrentSetupConfig
  fi
}

#-------------------------------------------------------------------------------
# Check for a setup config directory. If one exists, do nothing. If one doesn't
# exist, create it and it's parent if necessary, then set ownership to 
# "$SUDO_USER".
#-------------------------------------------------------------------------------
checkForSetupConfigDir () {
  echoComment "Checking for the setup config directory at $SETUP_CONF_DIR."

  if [ -d "$SETUP_CONF_DIR" ]; then
    echoComment "The setup config directory exists at $SETUP_CONF_DIR."
  else
    echoComment "The setup config directory does not exist at $SETUP_CONF_DIR."
    createSetupDir

    setOwner "$SUDO_USER" "$CONF_DIR"
    setOwner "$SUDO_USER" "$SETUP_CONF_DIR"
  fi
}

#-------------------------------------------------------------------------------
# Check for a current setup config file. If one doesn't exist, create it. If one
# does exist, ask if the user wants to remove it.
#-------------------------------------------------------------------------------
checkForSetupConfigFile () {
  echoComment "Checking for a setup config file in $SETUP_CONF_DIR."

  if [ -f "$SETUP_CONF" ]; then
    echoComment "A setup config file exists in $SETUP_CONF_DIR."
    removeCurrentSetupConfig
  else
    echoComment "No setup config file exists in $SETUP_CONF_DIR."
    createSetupConfig

    setPermissions 600 "$SETUP_CONF"
    setOwner "$SUDO_USER" "$SETUP_CONF"

    echoSeparator
    ls -lna "$SETUP_CONF_DIR"
    echoSeparator
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