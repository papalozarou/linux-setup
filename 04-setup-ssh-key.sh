#!/bin/sh

#-------------------------------------------------------------------------------
# Set up an ssh key for remote connections to the server.
#
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Get the name of the ssh key, and set the variable `$SSH_KEY`.
#-------------------------------------------------------------------------------
getSshKeyDetails () {
  read -p "$COMMENT_PREFIX"'What do you want to call your ssh key?' local REMOTE_KEY_NAME
  read -p "$COMMENT_PREFIX"'What email do you want to add to your ssh key?' SSH_EMAIL

  SSH_KEY=$SSH_DIR/$REMOTE_KEY_NAME
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
getSshKeyDetails
generateSshKey $SSH_KEY $SSH_EMAIL