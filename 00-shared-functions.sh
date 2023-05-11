#!/bin/sh

#-------------------------------------------------------------------------------
# Shared functons and variables used across the following server setup scripts:
#
# - 01-configure-git.sh
# - 02-change-password.sh
# - 03-change-username.sh
# - 04-setup-ssh-key.sh
# - 05-configure-sshd.sh
# - 06-configure-ufw.sh
# - 07-configure-fail2ban.sh
#
# N.B.
# To make this setup as portable as possible, all scripts are POSIX compliant,
# i.e they use #!/bin/sh not #!/bin/bash.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Comment variables.
#-------------------------------------------------------------------------------
COMMENT_PREFIX='SETUP SCRIPT: '
COMMENT_SEPARATOR="$COMMENT_PREFIX"'------------------------------------------------------------------'

#-------------------------------------------------------------------------------
# Generates an ssh key. Takes two arguments which specify a file path, `${1:?}`,
# and an optional email address, `$2`, for the key.
#-------------------------------------------------------------------------------
generateSshKey () {
  local KEY_PATH=${1:?}
  local KEY_EMAIL=$2

  echo "$COMMENT_PREFIX"'Generating an ssh key at '"$KEY_PATH"'.'
  echo "$COMMENT_SEPARATOR"

  if [ -z "$KEY_EMAIL" ]; then
    ssh-keygen -t ed25519 -f $KEY_PATH
  else
    ssh-keygen -t ed25519 -f $KEY_PATH -C "$KEY_EMAIL"
  fi

  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'Key generated.'
}

#-------------------------------------------------------------------------------
# Sets permissions of a file or directory. Takes two mandatory arguments, 
# defined by `${1:?}` and `${2:?}`, which specify a user and a path of the file
# or directory.
#-------------------------------------------------------------------------------
setPermissions () {
  local PERMISSIONS=${1:?}
  local FILE_FOLDER=${2:?}

  echo "$COMMENT_PREFIX"'Setting permissions of '"$FILE_FOLDER"' to '"$PERMISSIONS"'.'
  chmod -R $PERMISSIONS $FILE_FOLDER
}

#-------------------------------------------------------------------------------
# Sets ownership of a file or directory. Takes two mandatory arguments, defined
# by `${1:?}` and `${2:?}`, which specify the owner – also used for the group –
# and the path of the file or directory.
#-------------------------------------------------------------------------------
setOwner () {
  local USER=${1:?}
  local GROUP=$USER
  local FILE_FOLDER=${2:?}

  echo "$COMMENT_PREFIX"'Setting ownership of '"$FILE_FOLDER"' to '"$USER"':'"$GROUP"'.'
  chown -R $USER:$GROUP $FILE_FOLDER
}

#-------------------------------------------------------------------------------
# Updates and upgrades installed packages.
#-------------------------------------------------------------------------------
updateUpgrade () {
  echo "$COMMENT_PREFIX"'Updating and upgrading packages.'
  echo "$COMMENT_SEPARATOR"
  apt update && apt upgrade -y
  echo "$COMMENT_SEPARATOR"
}
