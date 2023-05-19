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
SETUP_CONF_DIR=~/.config/linux-setup
SETUP_CONF=$ETUP_CONF_DIR/setup.conf

#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
createSetupConfig () {
  echo "$COMMENT_PREFIX"'Creating setup config file in '"$SETUP_CONF_DIR"'.'
  cat <<EOF > $SETUP_CONF
lastCompletedStep 1
sshPort
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
#
#-------------------------------------------------------------------------------
checkForSetupConfig () {
  if [ -z $SETUP_CONF ]; then
    echo "$COMMENT_PREFIX"'No setup config file exists in '"$SETUP_CONF_DIR"'.'

    createSetupConfig
  else
    echo "$COMMENT_PREFIX"'A setup config file exists in '"$SETUP_CONF_DIR"'.'
    removeCurrentSetupConfig
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
updateUpgrade
checkForSetupConfig
echoScriptFinished 'initialising setup'

