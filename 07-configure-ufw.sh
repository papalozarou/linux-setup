#!/bin/sh

#-------------------------------------------------------------------------------
# Install and configure ufw to only accept traffic on required ports for ssh.
#
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Main script that checks to see if this step has been completed before. If so
# exit, if not run the setup for this step.
#-------------------------------------------------------------------------------
configureUfw () {
  local STEP_COMPLETED=$(checkSetupConfigOption configuredUfw)

  echo "$COMMENT_PREFIX"'Checking '"$SETUP_CONF"' to see if UFW has already been configured.'

  if [ $STEP_COMPLETED = true ]; then
    echo "$COMMENT_PREFIX"'UFW already configured. No setup required.'
    echoScriptExiting
  else
    echo "$COMMENT_PREFIX"'UFW not configured. Starting setup…'
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
configureUfw