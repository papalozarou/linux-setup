#!/bin/sh

#-------------------------------------------------------------------------------
# Change the user's password.
# 
# N.B.
# This script is run as sudo, the environment variable $SUDO_USER is used as the
# user for which the password is changed.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Change the password for the default ubuntu user.
#-------------------------------------------------------------------------------
echo "$COMMENT_PREFIX"'Change your password to a minimum of 24 characters, with a mix of alphanumerics'
echo "$COMMENT_PREFIX"'and symbols.'
passwd $SUDO_USER

#-------------------------------------------------------------------------------
# Display the status of the user's account.
#-------------------------------------------------------------------------------
echo "$COMMENT_PREFIX"'Your password has been successfully changed. Your account status is:'
echo "$COMMENT_PREFIX""(passwd -S $SUDO_USER)"