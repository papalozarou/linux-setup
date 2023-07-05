#!/bin/sh

#-------------------------------------------------------------------------------
# Change the current user's password.
# 
# N.B.
# As this script is run as "sudo", the environment variable "$SUDO_USER" is used 
# as the user for which the password is changed.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='changedPassword'

#-------------------------------------------------------------------------------
# Change the password for the default ubuntu user.
#-------------------------------------------------------------------------------
changeUserPassword () {
  echoComment "Changing password for $SUDO_USER"
  echoComment 'Please make sure your password is set to a minimum of 24 characters, using a mix of alphanumeric characters and symbols'
  echoSeparator
  passwd "$SUDO_USER"
  echoSeparator
}

#-------------------------------------------------------------------------------
# Display the status of the user's account.
#-------------------------------------------------------------------------------
displayUserAccountStatus() {
  echoComment 'Your password has been successfully changed. Listing your account status'
  echoSeparator
  echoComment "$(passwd -S "$SUDO_USER")"
  echoSeparator
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
main () {
  changeUserPassword
  displayUserAccountStatus
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"