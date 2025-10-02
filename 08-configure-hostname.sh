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
# - https://www.redhat.com/sysadmin/configure-hostname-linux
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
. ./linshafun/comments.sh
# . ./linshafun/crontab.sh
# . ./linshafun/docker-env-variables.sh
# . ./linshafun/docker-images.sh
# . ./linshafun/docker-secrets.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/docker-volumes.sh
# . ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
# . ./linshafun/host-information.sh
# . ./linshafun/host-initialisation.sh
# . ./linshafun/initialisation.sh
# . ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-config.sh
# . ./linshafun/ssh-keys.sh
# . ./linshafun/text.sh
. ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredHostname'

#-------------------------------------------------------------------------------
# Asks the user to change the hostname. Runs "setNewHostname" if yes, makes no
# changes if no.
#-------------------------------------------------------------------------------
changeHostname () {
  promptForUserInput 'Would you like to change the hostname (y/n)?'
  HOSTNAME_CHANGE_YN="$(getUserInputYN)"

  if [  "$HOSTNAME_CHANGE_YN" = true ]; then
    setNewHostname
  else
    printComment 'No changes made to hostname.'
  fi
}

#-------------------------------------------------------------------------------
# Checks the existing hostname.
#-------------------------------------------------------------------------------
checkHostname () {
  local CURRENT_HOSTNAME="$(hostname)"

  if [ -z "$CURRENT_HOSTNAME" ]; then
    printComment 'No hostname set.' 'warning'
  else
    printComment 'The current hostname is:'
    printComment "$CURRENT_HOSTNAME"
  fi
}

#-------------------------------------------------------------------------------
# Sets a new user inputed hostname.
#-------------------------------------------------------------------------------
setNewHostname () {
  promptForUserInput 'What is your new hostname (my.hostname.com)?'
  HOSTNAME="$(getUserInput)"

  printComment 'Setting hostname to:'
  printComment "$HOSTNAME"
  printComment 'You may be asked to authenticate.'
  hostnamectl set-hostname "$HOSTNAME"
  printComment 'Hostname is now set to:'
  hostname
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