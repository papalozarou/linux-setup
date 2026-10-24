#!/bin/sh

#-------------------------------------------------------------------------------
# Set the timezone and ntp server, by:
#
# 1. configuring the timezone; and
# 2. installing "ntpsec".
#
# Based on this Digital Ocean guide:
#
# - https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-ubuntu-20-04#conclusion
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
. ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-config.sh
# . ./linshafun/ssh-keys.sh
. ./linshafun/text.sh
. ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredTimezone'
SERVICE="ntpsec"

#-------------------------------------------------------------------------------
# Timezone related variables.
#-------------------------------------------------------------------------------
CURRENT_TIMEZONE="$(timedatectl show | grep "Timezone")"

#-------------------------------------------------------------------------------
# Lists the current settings, then asks if the user would like to change 
# the timezone. If not, no settings are changed. Returns 1 if the timezone
# can't be set.
#-------------------------------------------------------------------------------
changeTimezone () {
  listTimeDate
  printComment 'Your current timezone is:'
  printComment -- "$CURRENT_TIMEZONE"

  promptForUserInput 'Would you like to change the timezone (y/n)?'
  TIMEZONE_SET_YN=false
  if getUserInputYN; then TIMEZONE_SET_YN=true; fi

  if [ "$TIMEZONE_SET_YN" = true ]; then
    setNewTimezone
  else
    printComment 'No changes made to timezone settings.'
  fi 
}

#-------------------------------------------------------------------------------
# Checks the user inputted timezone is in "timedatectl list-timezones". Returns
# 0 if it is, otherwise 1. Takes one mandatory argument:
#
# 1. "${1:?}" – the user inputted timezone, e.g. "Europe/London".
#
# N.B.
# "grep -Fqx" matches the whole line as written. A partial match isn't enough,
# as some timezones are part of others, e.g. "UTC" is part of "Etc/UTC".
#-------------------------------------------------------------------------------
checkTimezone () {
  local TIMEZONE="${1:?}"

  timedatectl list-timezones | grep -Fqx -- "$TIMEZONE"
}

#-------------------------------------------------------------------------------
# Outputs ntpq settings.
#-------------------------------------------------------------------------------
listNtpSettings () {
  printComment 'Listing ntpq settings.'
  printSeparator
  ntpq -p
  printSeparator
  printComment --warning 'It may take a moment for connections to be established.'
}

#-------------------------------------------------------------------------------
# Outputs the time and date settings via "timedatectl".
#-------------------------------------------------------------------------------
listTimeDate () {
  printComment 'Listing time and date settings.'
  printSeparator
  timedatectl
  printSeparator
}

#-------------------------------------------------------------------------------
# Sets a new, user inputted, timezone, first checking the input is valid, then
# setting the new timezone.
#
# If the user inputs an invalid timezone the function is run again.
#
# Returns 1 with an error if the timezone can't be set, or if it can't be
# written to the setup config file.
#-------------------------------------------------------------------------------
setNewTimezone () {
  local NEW_TIMEZONE

  printComment 'You can find a list of timezones at:'
  printComment 'https://en.wikipedia.org/wiki/List_of_tz_database_time_zones'
  promptForUserInput 'Which timezone would you like to switch to (Region/City)?'
  NEW_TIMEZONE="$(getUserInput)"

  printComment "Checking $NEW_TIMEZONE is a valid timezone."

  if ! checkTimezone "$NEW_TIMEZONE"; then
    printComment --error 'Timezone is invalid. You must use a valid timezone.'

    setNewTimezone

    return
  fi

  printComment 'Timezone is valid.'

  printComment "Setting timezone to $NEW_TIMEZONE."

  if ! timedatectl set-timezone "$NEW_TIMEZONE"; then
    printComment --error "Failed to set the timezone to $NEW_TIMEZONE."

    return 1
  fi

  printComment "Timezone set."
  listTimeDate

  writeSetupConfigOption "timezone" "$NEW_TIMEZONE"
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script. Returns 1 as soon as a step fails.
#
# N.B.
# "timedatectl set-ntp no" turns off systemd's own time sync, so it doesn't
# run alongside "ntpsec".
#-------------------------------------------------------------------------------
mainScript () {
  changeTimezone || return 1

  printComment 'Ensuring set-ntp is off.'

  if ! timedatectl set-ntp no; then
    printComment --error 'Failed to turn off set-ntp.'

    return 1
  fi

  listTimeDate

  checkForPackagesAndInstall "$SERVICE" || return 1

  listNtpSettings
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
