#!/bin/sh

#-------------------------------------------------------------------------------
# Shared functons and variables used across the following server setup scripts:
#
# - 01-initialise-setup.sh
# - 02-configure-git.sh
# - 03-change-password.sh
# - 04-change-username.sh
# - 05-setup-ssh-key.sh
# - 06-configure-sshd.sh
# - 07-configure-ufw.sh
# - 08-configure-fail2ban.sh
#
# N.B.
# To make this setup as portable as possible, all scripts are POSIX compliant,
# i.e they use #!/bin/sh not #!/bin/bash.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Global variables used throughout the above scripts.
#-------------------------------------------------------------------------------
# Comment variables.
#---------------------------------------
COMMENT_PREFIX='SETUP SCRIPT: '
COMMENT_SEPARATOR="$COMMENT_PREFIX"'------------------------------------------------------------------'

#---------------------------------------
# Directory variables.
#---------------------------------------
USER_DIR=/home/$SUDO_USER
SSH_DIR=$USER_DIR/.ssh
CONF_DIR=$USER_DIR/.config
SETUP_CONF_DIR=$CONF_DIR/linux-setup

#---------------------------------------
# File variables.
#---------------------------------------
SETUP_CONF=$SETUP_CONF_DIR/setup.conf

#-------------------------------------------------------------------------------
# Check to see if the port number has already been used for another service.
#-------------------------------------------------------------------------------
checkPortNumber () {
  echo ""
}

#-------------------------------------------------------------------------------
# Echoes that the script given has finished. Takes one mandatory argument, 
# `${1:?}`, which is a comment.
#-------------------------------------------------------------------------------
echoScriptFinished () {
  local COMMENT=${1:?}

  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'Finished '"$COMMENT"'.'
  echo "$COMMENT_SEPARATOR"
}

#-------------------------------------------------------------------------------
# Generates a random port number between 2000 and 65000 inclusive, as per:
#
# https://unix.stackexchange.com/questions/140750/generate-random-numbers-in-specific-range
#-------------------------------------------------------------------------------
generatePortNumber () {
  echo "$(shuf -i 2000-65000 -n 1)"
}

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
# Installs a given service. Takes one mandatory argument, defined by `${1:?}`
# which defines the service to be installed.
#-------------------------------------------------------------------------------
installService () {
  local SERVICE=${1:?}
  
  echo "$COMMENT_PREFIX"'Installing '"$SERVICE"'.'
  echo "$COMMENT_SEPARATOR"
  apt install $SERVICE -y
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX""$SERVICE"' installed.'
}

#-------------------------------------------------------------------------------
# Reads a setup config option. Takes one mandatory argument, defined by 
# `${1:?}`, which defines the key of the config option.
#-------------------------------------------------------------------------------
readSetupConfigOption() {
  local CONFIG_KEY=${1:?}

  echo "$COMMENT_PREFIX"'Reading '"$CONFIG_KEY"'.'
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

#-------------------------------------------------------------------------------
# Writes a setup config option. Takes one mandatory argument, defined by 
# `${1:?}`, which defines the key of the config option.
#-------------------------------------------------------------------------------
writeSetupConfigOption() {
  local CONFIG_KEY=${1:?}

  echo "$COMMENT_PREFIX"'Writing '"$CONFIG_KEY"'.'
}
