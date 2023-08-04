#!/bin/sh

#-------------------------------------------------------------------------------
# Set the timezone and ntp server, by:
#
# 1. configuring the timezone; and
# 2. installing "ntp".
#
# N.B.
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredNtp'
SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" "lower")"

#-------------------------------------------------------------------------------
# Outputs ntpq settings.
#-------------------------------------------------------------------------------
listNtpSettings () {
  echoComment 'Listing ntpq settings.'
  echoSeparator
  ntpq -p
  echoSeparator
  echoComment 'It may take a moment for connections to be established.'
}

#-------------------------------------------------------------------------------
# Outputs the time and date settings via "timedatectl".
#-------------------------------------------------------------------------------
listTimeDate () {
  echoComment 'Listing time and date settings.'
  echoSeparator
  timedatectl
  echoSeparator
}

#-------------------------------------------------------------------------------
# Sets the timezone, listing the current settings, then asking if the user would
# like to change the timezone.
#-------------------------------------------------------------------------------
setTimezone () {
  local CURRENT_TIMEZONE="$(timedatectl show | grep "Timezone")"

  listTimeDate
  echoComment 'Your current timezone is:'
  echoComment "$CURRENT_TIMEZONE"

  echoComment 'Would you like to change the timezone?'
  read -r TIMEZONE_SET_YN

  if [  "$TIMEZONE_SET_YN" = 'y' -o "$TIMEZONE_SET_YN" = 'Y' ]; then
    echoComment 'Which timezone would you like to switch to (Region/City)?'
    read -r NEW_TIMEZONE
    
    echoComment "Setting timezone to $NEW_TIMEZONE."
    sudo timedatectl set-timezone "$NEW_TIMEZONE"
    echoComment "Timezone set."
    listTimeDate

    writeSetupConfigOption "timezone" "$NEW_TIMEZONE"
  elif [ "$TIMEZONE_SET_YN" = 'n' -o "$TIMEZONE_SET_YN" = 'N' ]; then
    echoComment 'No changes made to timezone settings.'

    writeSetupConfigOption "timezone" "$CURRENT_TIMEZONE"

    exit 1
  else
    echoComment 'You must answer y or n.'
    setTimezone
  fi 
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  setTimezone

  echoComment 'Ensuring set-ntp is off.'
  sudo timedatectl set-ntp no
  listTimeDate

  checkForServiceAndInstall "$SERVICE"

  listNtpSettings
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"