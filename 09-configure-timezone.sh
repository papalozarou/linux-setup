#!/bin/sh

#-------------------------------------------------------------------------------
# Set the timezone and ntp server, by:
#
# 1. configuring the timezone; and
# 2. installing "ntp".
#
# Based on this Digital Ocean guide:
#
# https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-ubuntu-20-04#conclusion
#
# N.B.
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported variables.
#-------------------------------------------------------------------------------
. ./linshafun/setup.var

#-------------------------------------------------------------------------------
# Imported shared functions.
#-------------------------------------------------------------------------------
. ./linshafun/comments.sh
# . ./linshafun/docker-env-variables.sh
# . ./linshafun/docker-images.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
# . ./linshafun/network.sh
# . ./linshafun/ownership-permissions.sh
. ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-keys.sh
# . ./linshafun/text.sh
. ./linshafun/user-input.sh
#-------------------------------------------------------------------------------
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredTimezone'
SERVICE="ntp"

#-------------------------------------------------------------------------------
# Timezone related variables.
#-------------------------------------------------------------------------------
CURRENT_TIMEZONE="$(timedatectl show | grep "Timezone")"

#-------------------------------------------------------------------------------
# Lists the current settings, then asks if the user would like to change 
# the timezone. If not, no settings are changed.
# 
# Any input other than "y", "Y", "n" or "N" will re-run this function.
#-------------------------------------------------------------------------------
changeTimezone () {
  listTimeDate
  echoComment 'Your current timezone is:'
  echoComment "$CURRENT_TIMEZONE"

  promptForUserInput 'Would you like to change the timezone?'
  TIMEZONE_SET_YN="$(getUserInput)"

  if [  "$TIMEZONE_SET_YN" = 'y' -o "$TIMEZONE_SET_YN" = 'Y' ]; then
    setNewTimezone
  elif [ "$TIMEZONE_SET_YN" = 'n' -o "$TIMEZONE_SET_YN" = 'N' ]; then
    echoComment 'No changes made to timezone settings.'
    
    echoScriptExiting

    exit 1
  else
    echoComment 'You must answer y or n.'
    changeTimezone
  fi 
}

#-------------------------------------------------------------------------------
# Checks the user inputted timezone. Takes one mandatory arguement:
#
# 1. ${1:?} - the user inputted timezone
#-------------------------------------------------------------------------------
checkTimezone () {
  local TIMEZONE="${1:?}"
  local TIMEZONE_CHECK="$(timedatectl list-timezones | grep "$TIMEZONE")"

  if [ "$TIMEZONE" = "$TIMEZONE_CHECK" ]; then
    echo true
  else
    echo false
  fi
}

#-------------------------------------------------------------------------------
# Outputs ntpq settings.
#-------------------------------------------------------------------------------
listNtpSettings () {
  echoComment 'Listing ntpq settings.'
  echoSeparator
  sh -c "ntpq -p"
  echoSeparator
  echoComment 'It may take a moment for connections to be established.'
}

#-------------------------------------------------------------------------------
# Outputs the time and date settings via "timedatectl".
#-------------------------------------------------------------------------------
listTimeDate () {
  echoComment 'Listing time and date settings.'
  echoSeparator
  sh -c "timedatectl"
  echoSeparator
}

#-------------------------------------------------------------------------------
# Sets a new, user inputted, timezone, first checking the input is valid, then
# setting the new timezone.
#
# If the user inputs an invalid timezone the function is run again.
#-------------------------------------------------------------------------------
setNewTimezone () {
  echoComment 'You can find a list of timezones at:'
  echoComment 'https://en.wikipedia.org/wiki/List_of_tz_database_time_zones'
  promptForUserInput 'Which timezone would you like to switch to (Region/City)?'
  NEW_TIMEZONE="$(getUserInput)"

  echoComment "Checking $NEW_TIMEZONE is valid…"
  local TIMEZONE_VALID="$(checkTimezone "$NEW_TIMEZONE")"

  if [ "$TIMEZONE_VALID" = true ]; then
    echoComment 'Timezone is valid.'

    echoComment "Setting timezone to $NEW_TIMEZONE."
    sh -c "timedatectl set-timezone $NEW_TIMEZONE"
    echoComment "Timezone set."
    listTimeDate

    writeSetupConfigOption "timezone" "$NEW_TIMEZONE"
  elif [ "$TIMEZONE_VALID" = false ]; then
    echoComment 'Timezone is invalid. You must use a valid timezone.'
    setNewTimezone
  fi
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  changeTimezone

  echoComment 'Ensuring set-ntp is off.'
  sh -c "timedatectl set-ntp no"
  listTimeDate

  checkForPackageAndInstall "$SERVICE"

  listNtpSettings
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"