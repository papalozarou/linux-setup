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
# Changes the case of text. Takes two mandatory arguements, the text string,
# `${1:?}`, and the required case, `${2:?}`. Based on the following articles:
#
# - https://medium.com/mkdir-awesome/case-transformation-in-bash-and-posix-with-examples-acdc1e0d0bc4
# - https://tech.io/snippet/JCFhOEk
#-------------------------------------------------------------------------------
changeCase () {
  local STRING=${1:?}
  local CASE=${2:?}

  if [ CASE = "upper" ]; then
    STRING=$(echo "$STRING" | tr '[:lower:]' '[:upper:]')
  elif [ CASE = "lower"]; then
    STRING=$(echo "$STRING" | tr '[:upper:]' '[:lower:]')
  # elif [ CASE = "sentence" ]; then
    # STRING="$(tr '[:lower:]' '[:upper:]' <<< ${STRING:0:1}) ${STRING:1}"
  fi

  echo $STRING
}

#-------------------------------------------------------------------------------
# Checks whether a given service is already installed. Takes one mandatory
# argument, `${1:?}`, which defines the service to be checked. Returns false if 
# the service is not installed, returns true if the service is installed.
#
# As per:
#
# https://stackoverflow.com/a/7522866
#-------------------------------------------------------------------------------
checkForService () {
  local SERVICE=${1:?}

  if ! type $SERVICE > /dev/null; then
    echo false
  else
    echo true   
  fi
}

#-------------------------------------------------------------------------------
# Checks for a setup config option. Takes one mandatory argument, defined by 
# `${1:?}`, which defines the key of the config option.
#
# The function returns `TRUE` or `FALSE` depending on if the config option is 
# present in the config file.
#-------------------------------------------------------------------------------
checkSetupConfigOption () {
  local CONFIG_KEY=${1:?}
  local CONFIG=$(grep $CONFIG_KEY $SETUP_CONF)

  if [ -z $CONFIG ]; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------------------
# Check to see if the port number has already been used for another service.
# Takes two mandatory arguement, defined by `${1:?}` and `${2:?}`, which define 
# the port to check and the config option key for the service to check against.
# 
# N.B.
# The config option key must be formatted exactly as in the config option file.
#-------------------------------------------------------------------------------
checkPortNumber () {
  local PORT=${1:?}
  local SERVICE=${2:?}
  local SERVICE_PORT=$(readSetupConfigOption $SERVICE)

  if [ $PORT = $SERVICE_PORT]; then
    echo true
  else 
    echo false
  fi
}

#-------------------------------------------------------------------------------
# Starts, stops or restarts a service. Takes two mandatory arguments which 
# specify the action, `${1:?}`, and the service, `{$2:?}`.
#-------------------------------------------------------------------------------
controlService () {
  local ACTION=${1:?}
  local SERVICE=${2:?}

  ACTION=$(changeCase $ACTION sentence)

  echo "$COMMENT_PREFIX""$ACTION"'ing '"$SERVICE"'.'
  echo "$COMMENT_SEPARATOR"
  if [ $SERVICE = 'ufw' ]; then
    $SERVICE $ACTION
  else
    systemctl $ACTION $SERVICE
  fi
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX""$ACTION"'ed '"$SERVICE"'.'
}

#-------------------------------------------------------------------------------
# Echose that the script is exiting. Takes no arguments.
#-------------------------------------------------------------------------------
echoScriptExiting () {
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'Exiting script with no changes made.'
  echo "$COMMENT_SEPARATOR"
}

#-------------------------------------------------------------------------------
# Echoes that the script has finished. Takes one mandatory argument, `${1:?}`, 
# which is a comment.
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
# Gets the IP address of the host machine.
#-------------------------------------------------------------------------------
getIPAddress () {
  echo "$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')"
}

#-------------------------------------------------------------------------------
# Initialises a given script by checking the config file to see if the script
# has been run and completed before. Takes one mandatory argument, `${1:?}`
# which defines the key to be checked in the `setup.conf` file.
#
# If the script has been run before, the script will exit. If not it will run.
# If there is an error, we ask the user to check the setup config file.
#-------------------------------------------------------------------------------
initialiseScript () {
  local CONFIG_KEY=${1:?}
  local CONFIG_KEY_TF=$(checkSetupConfigOption $CONFIG_KEY)

  echo "$COMMENT_PREFIX"'Checking '"$SETUP_CONF"' to see if this step has already been performed.'

  if [ $CONFIG_KEY = true ]; then
    echo "$COMMENT_PREFIX"'You have already performed this step.'
    echoScriptExiting
  elif [ $CONFIG_KEY = false ]; then
    echo "$COMMENT_PREFIX"'You have not performed this step. Running script.'
    echo "$COMMENT_SEPARATOR"
    runScript
  else
    echo "$COMMENT_PREFIX"'Something went wrong. Please check your setup config at '"$SETUP_CONF"'.'
  fi
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
# 
# The config line is read by `grep`` and stored in `$CONFIG`. This is split by 
# `set` into it's key, $1, and it's value, $2 – the `-f` flag prevents pathname 
# expansion for safety. Taken from:
#
# https://stackoverflow.com/a/1478245
#
# N.B.
# A list of the config keys can be found in `setup.conf.example`.
#-------------------------------------------------------------------------------
readSetupConfigOption () {
  local CONFIG_KEY=${1:?}
  local CONFIG="$(grep $CONFIG_KEY $SETUP_CONF)"

  set -f $CONFIG
  
  echo $2
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
# Writes a setup config option. Takes two mandatory arguments, the key of the 
# config option, `${1:?}`, and the value of the config option, `${2:?}`.
#
# Once the config option is written, the file ownership is set to `$SUDO_USER`.
#-------------------------------------------------------------------------------
writeSetupConfigOption () {
  local CONF_KEY=${1:?}
  local CONF_VALUE=${2:?}

  echo "$COMMENT_PREFIX"'Writing '"$CONF_KEY"' to '"$SETUP_CONF"'.'
  echo "$CONF_KEY $CONF_VALUE" >> $SETUP_CONF
  echo "$COMMENT_PREFIX"'Config written.'

  setOwner $SUDO_USER $SETUP_CONF
}
