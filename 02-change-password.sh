#!/bin/sh

#-------------------------------------------------------------------------------
# Change the current user's password.
# 
# N.B.
# As this script is run as sudo, the environment variable $SUDO_USER is used as 
# the user for which the password is changed.
#
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Change the password for the default ubuntu user.
#-------------------------------------------------------------------------------
changeUserPassword () {
  echo "$COMMENT_PREFIX"'Changing password for '"$SUDO_USER"'. Please make sure your'
  echo "$COMMENT_PREFIX"'password is set to a minimum of 24 characters, using a mix of'
  echo "$COMMENT_PREFIX"'alphanumeric characters and symbols'
  echo "$COMMENT_SEPARATOR"
  passwd $SUDO_USER
  echo "$COMMENT_SEPARATOR"
}

#-------------------------------------------------------------------------------
# Display the status of the user's account.
#-------------------------------------------------------------------------------
displayUserAccountStatus() {
  echo "$COMMENT_PREFIX"'Your password has been successfully changed. Your account status is:'
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"$(passwd -S $SUDO_USER)
  echo "$COMMENT_SEPARATOR"
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
changeUserPassword
displayUserAccountStatus