#!/bin/sh

#-------------------------------------------------------------------------------
# Initialises the setup by:
#
# 1. updating and upgrading packages; and
# 2. creating a config file in `~/.config/setup/setup.conf`
# 
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Set the config directory variable.
#-------------------------------------------------------------------------------
SETUP_CONF_DIR=/home/$SUDO_USER/.config/linux-setup
SETUP_CONF=$SETUP_CONF_DIR/setup.conf

#-------------------------------------------------------------------------------
# Creates the setup config directory at `$SETUP_CONF_DIR`.
#-------------------------------------------------------------------------------
createSetupDir () {
  echo "$COMMENT_PREFIX"'Creating setup config directory at '"$SETUP_CONF_DIR"'.'
  mkdir -p $SETUP_CONF_DIR

  echo "$COMMENT_SEPARATOR"
  ls -lna $SETUP_CONF_DIR
  echo "$COMMENT_SEPARATOR"

  echo "$COMMENT_PREFIX"'Setup config directory created.'
}

#-------------------------------------------------------------------------------
# Creates the basic setup config file in `$SETUP_CONF_DIR`.
#-------------------------------------------------------------------------------
createSetupConfig () {
  echo "$COMMENT_PREFIX"'Creating setup config file in '"$SETUP_CONF_DIR"'.'
  cat <<EOF > $SETUP_CONF
lastCompletedStep 1
EOF
  echo "$COMMENT_PREFIX"'Setup config file created.'
}

#-------------------------------------------------------------------------------
# Removes the setup config file within $SETUP_CONF, based on the users input.
#
# If the user requests to delete, the file is deleted.
#
# If the user doesn't request to delete, the file is left alone.
#
# Any input other than `y`, `Y`, `n` or `N` will re-run this function.
#-------------------------------------------------------------------------------
removeCurrentSetupConfig () {
  echo "$COMMENT_PREFIX"'Do you want to remove the setup config file in '"$SETUP_CONF_DIR"' (y/n)?' 
  read -p "$COMMENT_PREFIX"'N.B. This cannot be undone, and we wont ask for confirmation.' SETUP_CONF_YN

  if [ $SETUP_CONF_YN = 'y' -o $SETUP_CONF_YN = 'Y' ]; then
    echo "$COMMENT_PREFIX"'Deleting setup config file in '"$SETUP_CONF_DIR"'.'
    rm $SETUP_CONF
    echo "$COMMENT_PREFIX"'Setup config file deleted.'
  elif [ $SETUP_CONF_YN = 'n' -o $SETUP_CONF_YN = 'N' ]; then
    echo "$COMMENT_PREFIX"'Leaving setup config file in '"$SETUP_CONF_DIR"' intact.'
  else
    echo "$COMMENT_PREFIX"'You must answer y or n.'
    removeCurrentSetupConfig
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
checkForSetupConfigDir () {
  echo "$COMMENT_PREFIX"'Checking for the setup config directory at '"$SETUP_CONF_DIR"'.' 

  if [ -d $SETUP_CONF_DIR ]; then
    echo "$COMMENT_PREFIX"'The setup config directory exists at '"$SETUP_CONF_DIR"'.'
  else
    echo "$COMMENT_PREFIX"'The setup config directory does not exist at '"$SETUP_CONF_DIR"'.'
    createSetupDir

    setOwner $SUDO_USER $SETUP_CONF_DIR
  fi
}

#-------------------------------------------------------------------------------
# Check for a current setup config file. If one doesn't exist, create it. If one
# does exist, ask if the user wants to remove it.
#-------------------------------------------------------------------------------
checkForSetupConfigFile () {
  echo "$COMMENT_PREFIX"'Checking for a setup config file in '"$SETUP_CONF_DIR"'.'

  if [ -f $SETUP_CONF ]; then
    echo "$COMMENT_PREFIX"'A setup config file exists in '"$SETUP_CONF_DIR"'.'
    removeCurrentSetupConfig
  else
    echo "$COMMENT_PREFIX"'No setup config file exists in '"$SETUP_CONF_DIR"'.'
    createSetupConfig

    setPermissions 600 $SETUP_CONF
    setOwner $SUDO_USER $SETUP_CONF

    echo "$COMMENT_SEPARATOR"
    ls -lna $SETUP_CONF_DIR
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
updateUpgrade
checkForSetupConfigDir
checkForSetupConfigFile
echoScriptFinished 'initialising setup'

