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
SETUP_CONF=~/.config/linux-setup/setup.conf

#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
createSetupConfig () {
  echo "$COMMENT_PREFIX"'Creating setup config file at '"$SETUP_CONF"'.'
  cat <<EOF > $SETUP_CONF
setupStep
sshPort
EOF
  echo "$COMMENT_PREFIX"'Setup config created.'
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
  echo "$COMMENT_PREFIX"'Do you want to remove the setup config at '"$SETUP_CONF"' (y/n)?' 
  read -p "$COMMENT_PREFIX"'N.B. This cannot be undone, and we wont ask for confirmation.' SETUP_CONF_YN

  if [ $SETUP_CONF_YN = 'y' -o $SETUP_CONF_YN = 'Y' ]; then
    echo "$COMMENT_PREFIX"'Deleting '"$SETUP_CONF"'.'
    rm $SETUP_CONF
    echo "$COMMENT_PREFIX"'Setup config deleted.'
  elif [ $SETUP_CONF_YN = 'n' -o $SETUP_CONF_YN = 'N' ]; then
    echo "$COMMENT_PREFIX"'Leaving '"$SETUP_CONF"' intact.'
  else
    echo "$COMMENT_PREFIX"'You must answer y or n.'
    removeCurrentSetupConfig
  fi
}

#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
checkForSetupConfig () {
  if [ -z ]
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
updateUpgrade
checkForSetupConfig

