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
# . ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='changedPassword'

#-------------------------------------------------------------------------------
# Change the password for the default ubuntu user.
#-------------------------------------------------------------------------------
changeUserPassword () {
  printComment "Changing password for $SUDO_USER."
  printComment 'Please make sure your password is set to a minimum of 24 characters, using a mix of alphanumeric characters and symbols.' 'warning'
  printSeparator
  passwd "$SUDO_USER"
  printSeparator
}

#-------------------------------------------------------------------------------
# Display the status of the user's account.
#-------------------------------------------------------------------------------
displayUserAccountStatus() {
  printComment 'Your password has been successfully changed. Listing your account status:'
  printSeparator
  passwd -S "$SUDO_USER"
  printSeparator
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