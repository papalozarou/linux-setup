#!/bin/sh

#-------------------------------------------------------------------------------
# Change the current user's password.
# 
# N.B.
# As this script is run as "sudo", the environment variable "$SUDO_USER" is used 
# as the user for which the password is changed.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported shared variables.
#-------------------------------------------------------------------------------
. ./linshafun/linshafun.var

#-------------------------------------------------------------------------------
# Imported project specific variables.
#-------------------------------------------------------------------------------
. ./linux-setup.var
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
# . ./linshafun/host-information.sh
# . ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-keys.sh
# . ./linshafun/text.sh
# . ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='changedPassword'

#-------------------------------------------------------------------------------
# Change the password for the default ubuntu user.
#-------------------------------------------------------------------------------
changeUserPassword () {
  echoComment "Changing password for $SUDO_USER."
  echoComment 'Please make sure your password is set to a minimum of 24 characters,'
  echoComment 'using a mix of alphanumeric characters and symbols.'
  echoSeparator
  passwd "$SUDO_USER"
  echoSeparator
}

#-------------------------------------------------------------------------------
# Display the status of the user's account.
#-------------------------------------------------------------------------------
displayUserAccountStatus() {
  echoComment 'Your password has been successfully changed.' 
  echoComment 'Listing your account status:'
  echoSeparator
  echoComment "$(passwd -S "$SUDO_USER")"
  echoSeparator
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  changeUserPassword
  displayUserAccountStatus
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"