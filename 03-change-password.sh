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
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-config.sh
# . ./linshafun/ssh-keys.sh
. ./linshafun/text.sh
# . ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='changedPassword'

#-------------------------------------------------------------------------------
# Change the password for the default ubuntu user. Returns 1 with an error if
# "passwd" fails, e.g. when the two passwords entered don't match.
#-------------------------------------------------------------------------------
changeUserPassword () {
  local STATUS=0

  printComment "Changing password for $SUDO_USER."
  printComment --warning 'Please make sure your password is set to a minimum of 24 characters, using a mix of alphanumeric characters and symbols.'
  printSeparator
  passwd "$SUDO_USER" || STATUS=1
  printSeparator

  if [ "$STATUS" -ne 0 ]; then
    printComment --error "Failed to change the password for $SUDO_USER."

    return 1
  fi
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
# Executes the main functions of the script. Returns 1 if the password can't be
# changed.
#-------------------------------------------------------------------------------
mainScript () {
  changeUserPassword || return 1
  displayUserAccountStatus
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
