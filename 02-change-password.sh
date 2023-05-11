#!/bin/sh

#-------------------------------------------------------------------------------
# Change the current user's password.
# 
# N.B.
# As this script is run as sudo, the environment variable $SUDO_USER is used as 
# the user for which the password is changed.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Change the password for the default ubuntu user.
#-------------------------------------------------------------------------------
changeUserPassword () {
  echo "$COMMENT_PREFIX"'Change your password to a minimum of 24 characters, with a mix of alphanumerics'
  echo "$COMMENT_PREFIX"'and symbols.'
  passwd $SUDO_USER
}

#-------------------------------------------------------------------------------
# Display the status of the user's account.
#-------------------------------------------------------------------------------
displayUserAccountStatus() {
  echo "$COMMENT_PREFIX"'Your password has been successfully changed. Your account status is:'
  echo "$COMMENT_PREFIX""(passwd -S $SUDO_USER)"
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
changeUserPassword
displayUserAccountStatus