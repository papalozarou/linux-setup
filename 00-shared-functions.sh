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
# To make this setup as portable as possible, all scripts use sh not bash.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Comment variables.
#-------------------------------------------------------------------------------
COMMENT_PREFIX='Setup script: '

#-------------------------------------------------------------------------------
# Config variables.
#-------------------------------------------------------------------------------
SETUP_CONF_DIR='~/.config/server-setup'

#-------------------------------------------------------------------------------
# Checks to see if the config directory has been created in ~/.config. If not it
# will create it.
#-------------------------------------------------------------------------------
configDirCheck () {
  echo "$COMMENT_PREFIX"'Preflight check.'

  if [ -d $SETUP_CONF_DIR ]; then
    echo "$COMMENT_PREFIX"'Config directory detected at '"$SETUP_CONF_DIR"'.'
    mkdir -p $SETUP_CONF_DIR
    chownConfigDir

    echo "$COMMENT_PREFIX"'Config directory created at '"$SETUP_CONF_DIR"'.'
  fi
}

#-------------------------------------------------------------------------------
# Checks for a the presence of a config file. Takes one mandatory argument, 
# defined by `${1:?}`, which defines the config file to check.
#-------------------------------------------------------------------------------
configCheck () {
  local KEY=${1:?}

  if [ -f $SETUP_CONF_DIR/$KEY ]; then
    echo '0'
  else
    echo '1'
  fi
}

#-------------------------------------------------------------------------------
# Reads the value of a config file. Takes one mandatory argument, defined by 
# `${1:?}`, which defines the config file to read.
#-------------------------------------------------------------------------------
configRead () {
  local KEY=${1:?}

  echo $(<$SETUP_CONF_DIR/$KEY)
}

#-------------------------------------------------------------------------------
# Writes a config file. Takes two mandatory arguments, defined by `${1:?}` and 
# `${2:?}`, which specify a key and a value pair. The key is used for the 
# filename, which will only contain the value. Once written the config dir is 
# chowned to the current user as the file is written by root.
#
# N.B.
# At some point this should be re-written to house all key values in a single
# file.
#-------------------------------------------------------------------------------
configWrite () {
  local KEY=${1:?}
  local VALUE=${2:?}

  if [ $KEY == 'SETUP_STEP' ]; then
    VALUE=$(($(configRead $KEY)+1))
  fi

  cat <<EOF > $SETUP_CONF_DIR/$KEY
$VALUE
EOF

  echo "$COMMENT_PREFIX"'Config file written for '"$KEY"' with value '"$VALUE"'.'
  chownConfigDir
}

#-------------------------------------------------------------------------------
# Generates an ssh key. Takes two mandatory arguments, defined by `${1:?}` and 
# `${2:?}`, which specify a file path and an email address for the key.
#-------------------------------------------------------------------------------
generateSshKey () {
  local KEY_PATH=${1:?}
  local KEY_EMAIL=${2:?}

  echo "$COMMENT_PREFIX"'Generating an ssh key at '"$KEY_PATH"'.'
  ssh-keygen -t ed25519 -f $KEY_PATH -C "$KEY_EMAIL"
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

  apt update && apt upgrade -y
}
