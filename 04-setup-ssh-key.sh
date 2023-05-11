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
  read -p "$COMMENT_PREFIX"'What do you want to call your ssh key?' REMOTE_KEY_NAME
  read -p "$COMMENT_PREFIX"'What email do you want to add to your ssh key?' SSH_EMAIL

  SSH_KEY=$SSH_DIR/$REMOTE_KEY_NAME
}

#-------------------------------------------------------------------------------
# Adds the newly generated public key to the `authorized_keys` file.
#-------------------------------------------------------------------------------
addKeyToAuthorizedKeys () {
  echo "$COMMENT_PREFIX"'Adding public key to '"$SSH_DIR"'/authorized_keys.'
  cat $SSH_KEY.pub >> $SSH_DIR/authorized_keys
  echo "$COMMENT_PREFIX"'Key added.'
}

#-------------------------------------------------------------------------------
# Tell the user to copy the private key to their local machine.
#-------------------------------------------------------------------------------
keyUsage () {
<<<<<<< HEAD
  echo "$COMMENT_PREFIX"'Please copy the private key, '"$REMOTE_KEY_NAME"', to your local .ssh'
=======
  echo "$COMMENT_PREFIX"'Please copy the private key, '"$REMOTE_KEY_NAME"' to your local .ssh'
>>>>>>> 2ed5dcbc3c4097c47c67325cca60abd904257d6d
  echo "$COMMENT_PREFIX"'~/.ssh directory. YOu will also want to add this host to your ssh'
  echo "$COMMENT_PREFIX"'config file, either ~/.ssh/ssh_config or ~/.ssh/config.'
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
getSshKeyDetails
generateSshKey $SSH_KEY $SSH_EMAIL
setOwner $SUDO_USER $SSH_KEY
setOwner $SUDO_USER $SSH_KEY.pub
addKeyToAuthorizedKeys
keyUsage