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
COMMENT_PREFIX='SETUP SCRIPT:'
COMMENT_SEPARATOR='------------------------------------------------------------------'

#---------------------------------------
# Directory variables.
#---------------------------------------
USER_DIR="/home/$SUDO_USER"
SSH_DIR="$USER_DIR/.ssh"
CONF_DIR="$USER_DIR/.config"
SETUP_CONF_DIR="$CONF_DIR/linux-setup"

#---------------------------------------
# File variables.
#---------------------------------------
SETUP_CONF="$SETUP_CONF_DIR/setup.conf"

#-------------------------------------------------------------------------------
# Adds a port to ufw. Takes three arguments:
#
# 1. "${1:?}" – a mandatory action, either "allow", "deny" or "limit";
# 2. "${2:?}" – a mandatory port number; and
# 3. "$3" – an optional protocol
#-------------------------------------------------------------------------------
addRuleToUfw () {
  local ACTION="${1:?}"
  local PORT="${2:?}"
  local PROTOCOL="$3"

  if [ -z "$PROTOCOL" ]; then
      echoComment "Adding rule $ACTION $PORT to UFW."
      echoSeparator
      ufw "$ACTION" "$PORT"
      echoSeparator
  else
    echoComment "Adding rule $ACTION $PORT/$PROTOCOL to UFW."
    echoSeparator
    ufw "$ACTION" "$PORT/$PROTOCOL"
    echoSeparator
  fi

  echoComment 'Rule added.'
}

#-------------------------------------------------------------------------------
# Changes the case of text. Takes two mandatory arguements:
# 
# 1. "${1:?}" – a text string; and
# 2. "${2:?}" – the required case.
# 
# Based on the following articles:
#
# - https://medium.com/mkdir-awesome/case-transformation-in-bash-and-posix-with-examples-acdc1e0d0bc4
# - https://tech.io/snippet/JCFhOEk
# - https://unix.stackexchange.com/a/554909
#-------------------------------------------------------------------------------
changeCase () {
  local STRING="${1:?}"
  local CASE="${2:?}"

  if [ "$CASE" = 'upper' ]; then
    STRING=$(echo "$STRING" | tr '[:lower:]' '[:upper:]')
  elif [ "$CASE" = 'lower' ]; then
    STRING=$(echo "$STRING" | tr '[:upper:]' '[:lower:]')
  elif [ "$CASE" = 'sentence' ]; then
    STRING=$(echo "$STRING" | sed 's/\<\([[:lower:]]\)\([^[:punct:]]*\)/\u\1\2/g')
  fi

  echo "$STRING"
}

#-------------------------------------------------------------------------------
# Checks whether a given service is already installed. Takes one mandatory
# argument:
# 
# 1. "${1:?}" – the service to be checked. 
# 
# Returns false if the service is not installed, returns true if the service is 
# installed. As per:
#
# https://stackoverflow.com/a/7522866
#-------------------------------------------------------------------------------
checkForService () {
  local SERVICE="${1:?}"

  if ! type "$SERVICE" > /dev/null; then
    echo false
  else
    echo true   
  fi
}

#-------------------------------------------------------------------------------
# Uses the above function to check for a service and if not installed installs
# it. Takes one mandatory argument:
# 
# 1. "${1:?}" – the service.
#-------------------------------------------------------------------------------
checkForServiceAndInstall () {
  local SERVICE="${1:?}"
  echoComment "Starting setup of $SERVICE."

  local SERVICE_CHECK="$(checkForService "$SERVICE")"
  echoComment "Checking for $SERVICE."
  echoComment "Check returned $SERVICE_CHECK."

  if [ "$SERVICE_CHECK" = true ]; then
    echoComment "You have already installed $SERVICE."
  elif [ "$SERVICE_CHECK" = false ]; then
    echoComment "You need to install $SERVICE."
    installService "$SERVICE"
  fi
}

#-------------------------------------------------------------------------------
# Check to see if the port number has already been used for another service.
# Takes two mandatory arguement:
# 
# 1. "${1:?}" – the port to check; and
# 2. "${2:?}" – the config option key for the service to check against.
# 
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example".
#-------------------------------------------------------------------------------
checkPortNumber () {
  local PORT="${1:?}"
  local SERVICE="${2:?}"
  local SERVICE_PORT="$(readSetupConfigOption "$SERVICE")"

  if [ "$PORT" = "$SERVICE_PORT" ]; then
    echo true
  else 
    echo false
  fi
}

#-------------------------------------------------------------------------------
# Checks for a setup config option. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key of the config option.
#
# The function returns true or false depending on if the config option is 
# present in the config file.
# 
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example".
#-------------------------------------------------------------------------------
checkSetupConfigOption () {
  local CONFIG_KEY="${1:?}"
  local CONFIG="$(grep "$CONFIG_KEY" "$SETUP_CONF")"

  if [ -z "$CONFIG" ]; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------------------
# Starts, stops or restarts a service. Takes two mandatory arguments:
#  
# 1. "${1:?}" – specifying the action; and
# 2. "${2:?}" – the service.
#-------------------------------------------------------------------------------
controlService () {
  local ACTION="${1:?}"
  local SERVICE="${2:?}"

  if [ "$ACTION" = 'enable' ]; then
    ACTIONING="Enabling"
  elif [ "$ACTION" = 'disable' ]; then
    ACTIONING="Disabling"
  elif [ "$ACTION" = 'start' ]; then
    ACTIONING="Starting"
  elif [ "$ACTION" = 'stop' ]; then
    ACTIONING="Stopping"
  elif [ "$ACTION" = 'restart' ]; then
    ACTIONING="Restarting"
  elif [ "$ACTION" = 'status' ]; then
    ACTIONING='Checking status of'
  else
    ACTIONING="$(changeCase "$ACTION" sentence)ing"
  fi

  echoComment "$ACTIONING $SERVICE."
  echoSeparator

  if [ "$SERVICE" = 'ufw' ]; then
    "$SERVICE" "$ACTION"
  else
    systemctl "$ACTION" "$SERVICE"
  fi
  echoSeparator
}

#-------------------------------------------------------------------------------
# Echoes comments. Takes one mandatory argument:
# 
# 1. "${1:?}" – a comment.
#-------------------------------------------------------------------------------
echoComment () {
  local COMMENT="${1:?}"

  echo "$COMMENT_PREFIX $COMMENT"
}

#-------------------------------------------------------------------------------
# Echoes that the script is exiting. Takes no arguments.
#-------------------------------------------------------------------------------
echoScriptExiting () {
  echoSeparator
  echoComment 'Exiting script with no changes made.'
  echoSeparator
}

#-------------------------------------------------------------------------------
# Echoes comment separator. Takes no arguments.
#-------------------------------------------------------------------------------
echoSeparator () {
  echoComment "$COMMENT_SEPARATOR"
}

#-------------------------------------------------------------------------------
# Finishes the script by writing in the config key and echoing the script has
# finished. Takes one mandatory argument:
# 
# 1. "${1:?}" – the config key to be written.
#
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example".
#-------------------------------------------------------------------------------
finaliseScript () {
  local CONFIG_KEY="${1:?}"

  writeSetupConfigOption "$CONFIG_KEY" true

  echoSeparator
  echoComment 'Script finished.'
  echoSeparator
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
# Generates an ssh key. Takes two arguments:
#
# 1. "${1:?}" – specify a file path; and
# 2. "$2" – an optional email address for the key.
#-------------------------------------------------------------------------------
generateSshKey () {
  local KEY_PATH="${1:?}"
  local KEY_EMAIL="$2"

  echoComment "Generating an ssh key at $KEY_PATH."
  echoSeparator

  if [ -z "$KEY_EMAIL" ]; then
    ssh-keygen -t ed25519 -f "$KEY_PATH"
  else
    ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$KEY_EMAIL"
  fi

  echoSeparator
  echoComment 'Key generated.'
}

#-------------------------------------------------------------------------------
# Gets the IP address of the host machine.
#-------------------------------------------------------------------------------
getIPAddress () {
  echo "$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')"
}

#-------------------------------------------------------------------------------
# Gets a service name from a given config key. Takes one mandatory argument:
# 
# 1. "${1:?}" – the config option key to be used.
#
# If the config key contains a service, "$SERVICE" is returned. If not, nothing
# is returned.
# 
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example".
#-------------------------------------------------------------------------------
getServiceFromConfigKey () {
  local CONFIG_KEY="${1:?}"

  if [ -z "${CONFIG_KEY##configured*}" ]; then
    local SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" 'lower')"

    echo "$SERVICE"
  fi
}

#-------------------------------------------------------------------------------
# Checks the config file to see if the script has been run and completed before.
# Takes one mandatory arguement:
#
# 1. "${1:?}" – the config option key to be used.
#
# If the script has been run before, the script will exit. If not it will run.
# If there is an error, we ask the user to check the setup config file and then
# exit the script.
# 
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example".
#-------------------------------------------------------------------------------
initialiseScript () {
  local CONFIG_KEY="${1:?}"
  local CONFIG_KEY_TF="$(checkSetupConfigOption "$CONFIG_KEY")"

  echoComment "Checking $SETUP_CONF to see if this step has already been performed."
  echoComment "Check returned $CONFIG_KEY_TF."

  if [ "$CONFIG_KEY_TF" = true ]; then
    echoComment 'You have already performed this step.'
    echoScriptExiting

    exit 1
  elif [ "$CONFIG_KEY_TF" = false ]; then
    echoComment 'You have not performed this step. Running script.'
    echoSeparator
  else
    echoComment "Something went wrong. Please check your setup config at $SETUP_CONF."
    echoScriptExiting

    exit 1
  fi
}

#-------------------------------------------------------------------------------
# Installs a given service. Takes one mandatory argument:
# 
# 1. "${1:?}" – the service to be installed.
#-------------------------------------------------------------------------------
installService () {
  local SERVICE="${1:?}"
  
  echoComment "Installing $SERVICE."
  echoSeparator
  apt install "$SERVICE" -y
  echoSeparator
  echoComment "$SERVICE installed."
}

#-------------------------------------------------------------------------------
# Reads a setup config option. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key of the config option.
# 
# The config line is read by "grep" and stored in "$CONFIG". This is split by 
# "set" into it's key, "$1", and it's value, "$2" – the "-f" flag prevents pathname 
# expansion for safety. Taken from:
#
# https://stackoverflow.com/a/1478245
# 
# N.B.
# "$CONFIG" is not quoted as we need word splitting in this instance. 
#
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example".
#-------------------------------------------------------------------------------
readSetupConfigOption () {
  local CONFIG_KEY="${1:?}"
  local CONFIG="$(grep "$CONFIG_KEY" "$SETUP_CONF")"

  set -f $CONFIG
  
  echo "$2"
}

#-------------------------------------------------------------------------------
# Sets permissions of a file or directory. Takes two mandatory arguments:
# 
# 1. "${1:?}" – a user; and
# 2. "${2:?}" – the path of the file or directory.
#-------------------------------------------------------------------------------
setPermissions () {
  local PERMISSIONS="${1:?}"
  local FILE_FOLDER="${2:?}"

  echoComment "Setting permissions of $FILE_FOLDER to $PERMISSIONS."
  chmod -R "$PERMISSIONS" "$FILE_FOLDER"
}

#-------------------------------------------------------------------------------
# Sets ownership of a file or directory. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the owner, also used for the group; and
# 2. "${2:?}" – the path of the file or directory.
#-------------------------------------------------------------------------------
setOwner () {
  local USER="${1:?}"
  local GROUP="$USER"
  local FILE_FOLDER="${2:?}"

  echoComment "Setting ownership of $FILE_FOLDER to $USER:$GROUP."
  chown -R "$USER:$GROUP" "$FILE_FOLDER"
}

#-------------------------------------------------------------------------------
# Updates and upgrades installed packages.
#-------------------------------------------------------------------------------
updateUpgrade () {
  echoComment 'Updating and upgrading packages.'
  echoSeparator
  apt update && apt upgrade -y
  echoSeparator
}

#-------------------------------------------------------------------------------
# Writes a setup config option. Takes two mandatory arguments:
#
# 1. "${1:?}" – the key of the config option; and
# 2. "${2:?}" – the value of the config option.
#
# Once the config option is written, the file ownership is set to "$SUDO_USER".
# 
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example".
#-------------------------------------------------------------------------------
writeSetupConfigOption () {
  local CONF_KEY="${1:?}"
  local CONF_VALUE="${2:?}"

  echoComment "Writing $CONF_KEY to $SETUP_CONF."
  echo "$CONF_KEY $CONF_VALUE" >> "$SETUP_CONF"
  echoComment 'Config written.'

  setOwner "$SUDO_USER" "$SETUP_CONF"
}