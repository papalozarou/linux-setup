#!/bin/sh

#-------------------------------------------------------------------------------
# Set the hostname, by:
#
# 1. checking the current hostname;
# 2. asking if the user wants to change it or creat one if unset; and
# 3. setting a hostname 
#
# Based on this RedHat guide:
#
# https://www.redhat.com/sysadmin/configure-hostname-linux
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
CONFIG_KEY='configuredHostname'

#-------------------------------------------------------------------------------
# Asks the user to change the hostname. Runs "setNewHostname" if yes, exits if
# no, otherwise re-runs.
#-------------------------------------------------------------------------------
changeHostname () {
  echoComment 'Would you like to change the hostname?'
  read -r HOSTNAME_CHANGE_YN

  if [  "$HOSTNAME_CHANGE_YN" = 'y' -o "$HOSTNAME_CHANGE_YN" = 'Y' ]; then
    setNewHostname
  elif [ "$HOSTNAME_CHANGE_YN" = 'n' -o "$HOSTNAME_CHANGE_YN" = 'N' ]; then
    echoComment 'No changes made to hostname.'
    echoScriptExiting
    exit 1
  else
    echoComment 'You must answer y or n.'
    changeHostname
  fi 
}

#-------------------------------------------------------------------------------
# Checks the existing hostname.
#-------------------------------------------------------------------------------
checkHostname () {
  local CURRENT_HOSTNAME="$(hostname)"

  if [ -z "$CURRENT_HOSTNAME" ]; then
    echoComment 'No hostname set.'
  else
    echoComment 'The current hostname is:'
    echoComment "$CURRENT_HOSTNAME"
  fi
}

#-------------------------------------------------------------------------------
# Sets a new user inputed hostname.
#-------------------------------------------------------------------------------
setNewHostname () {
  echoComment 'What is your new hostname (my.hostname.com)?'
  read -r HOSTNAME

  echoComment "Setting hostname to $HOSTNAME. You may be asked to authenticate."
  echoSeparator
  hostnamectl set-hostname "$HOSTNAME"
  echoSeparator
  echoComment 'Hostname set.'
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  checkHostname
  changeHostname
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"