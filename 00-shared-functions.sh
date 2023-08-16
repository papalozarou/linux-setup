#!/bin/sh

#-------------------------------------------------------------------------------
# Shared functions and variables used across the following server setup scripts:
#
# - 01-initialise-setup.sh
# - 02-change-password.sh
# - 03-change-username.sh
# - 04-setup-ssh-key.sh
# - 05-configure-sshd.sh
# - 06-configure-ufw.sh
# - 07-configure-fail2ban.sh
# - 08-configure-hostname.sh
# - 09-configure-timezone.sh
# - 10-configure-git.sh
# - 11-configure-docker.sh
# - 12-set-env-variables.sh
#
# Functions try to use "verbValue/Object" as naming conventions:
#
# - "addFooBar" – adds a value to an existing object;
# - "changeFooBar" - changes an already set value;
# - "checkFooBar" - checks if a value or object exists;
# - "createFooBar" - creates an object;
# - "generateFooBar" - generates a value or object automatically;
# - "getFooBar" - asks the user for input to set a value, or gets a substring
#   from an existing value or object;
# - "readFooBar" - reads an already set value; and
# - "setFooBar" - sets a value.
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
SUDOERS_CONF_DIR="$SUDOERS.d"

#---------------------------------------
# File variables.
#---------------------------------------
SETUP_CONF="$SETUP_CONF_DIR/setup.conf"
PROFILE="$(find "$USER_DIR" -type f \( -name ".bashrc" -o -name ".bash_profile" \))"
SUDOERS='/etc/sudoers'
SUDOERS_DEFAULT_CONF="$SUDOERS_CONF_DIR/99-default-env-keep"

#-------------------------------------------------------------------------------
# Adds a "env_keep" statement for a given environment variable. Takes one 
# mandatory arguement:
# 
# 1. "${1:?}" -the  name of the environment variable.
# 
# N.B.
# This function assumes that the sudoers config file exists as it is created 
# in "set-env-variables.sh".
#-------------------------------------------------------------------------------
addHostEnvVariableToSudoersConf () {
  local ENV_VARIABLE="${1:?}"
  local ENV_KEEP="Defaults env_keep += \"$ENV_VARIABLE\""

  echo "$ENV_KEEP" >> "$SUDOERS_DEFAULT_CONF"
}

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
checkAgainstExistingPortNumber () {
  local PORT="${1:?}"
  local SERVICE="${2:?}Port"
  local SERVICE_PORT="$(readSetupConfigOption "$SERVICE")"

  if [ "$PORT" = "$SERVICE_PORT" ]; then
    echo true
  else 
    echo false
  fi
}

#-------------------------------------------------------------------------------
# Checks for a given environment variable in "$PROFILE". Returns true if the 
# variable is present, returns false if not. Takes one mandatory argument:
# 
# 1. "{1:?}" - the name of the environment variable.
#-------------------------------------------------------------------------------
checkForHostEnvVariable () {
  local ENV_VARIABLE="${1:?}"
  local ENV_TF="$(grep "$ENV_VARIABLE" "$PROFILE")"

  if [ -z "$ENV_TF" ]; then
    echo false
  else
    echo true
  fi
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

  local SERVICE_TF="$(checkForService "$SERVICE")"
  echoComment "Checking for $SERVICE."
  echoComment "Check returned $SERVICE_TF."

  if [ "$SERVICE_TF" = true ]; then
    echoComment "You have already installed $SERVICE."
  elif [ "$SERVICE_TF" = false ]; then
    echoComment "You need to install $SERVICE."
    installRemovePackages "install" "$SERVICE"
  fi
}

#-------------------------------------------------------------------------------
# Check for a setup config directory. If one exists, do nothing. If one doesn't
# exist, create it and it's parent if necessary, then set ownership to 
# "$SUDO_USER".
#-------------------------------------------------------------------------------
checkForSetupConfigDir () {
  echoComment 'Checking for the setup config directory at:'
  echoComment "$SETUP_CONF_DIR."

  if [ -d "$SETUP_CONF_DIR" ]; then
    echoComment 'The setup config directory exists.'
  else
    echoComment 'The setup config directory does not exist.'
    createDirectory "$SETUP_CONF_DIR"

    setOwner "$SUDO_USER" "$CONF_DIR"
    setOwner "$SUDO_USER" "$SETUP_CONF_DIR"
  fi

  listDirectories "$SETUP_CONF_DIR"
}

#-------------------------------------------------------------------------------
# Check for a current setup config file. If one exists, do nothing. If one 
# doesn't exist, create it, then set ownership to "$SUDO_USER".
#-------------------------------------------------------------------------------
checkForSetupConfigFile () {
  echoComment 'Checking for a setup config file in:' 
  echoComment "$SETUP_CONF_DIR."

  if [ -f "$SETUP_CONF" ]; then
    echoComment 'A setup config file exists.'
  else
    echoComment 'No setup config file exists.'
    createFiles "$SETUP_CONF"

    setPermissions 600 "$SETUP_CONF"
    setOwner "$SUDO_USER" "$SETUP_CONF"
  fi

  listDirectories "$SETUP_CONF_DIR"
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
# Creates directories and subdirectories, using "createDirectory". Takes two 
# arguments:
# 
# 1. "${1:?}" - a mandatory single directory path, or multiple directory paths 
#    separated by spaces; and
# 2. "$2" - an optional subdirectory name, or multiple subdirectory names
#    separated by spaces.
#
# All directories, and parent directories if required, are created.
# 
# N.B.
# "$MAIN_DIR" and "$SUB_DIRS" are not quoted as we explicitly want word 
# splitting here.
# 
# And yes it's a nested loop. What of it?
#-------------------------------------------------------------------------------
createDirectories () {
  local MAIN_DIRS=${1:?}
  local SUB_DIRS=$2

  if [ -z "$SUB_DIRS" ]; then
    for DIR in $MAIN_DIRS; do
      createDirectory "$DIR"
      listDirectories "$DIR"
    done
  else
    for DIR in $MAIN_DIRS; do
      PARENT_DIR="$DIR"
      for SUB_DIR in $SUB_DIRS; do
        DIR_SUB_DIR="$PARENT_DIR/$SUB_DIR"
        
        createDirectory "$DIR_SUB_DIR"
        listDirectories "$DIR_SUB_DIR"
      done
    done
  fi
}

#-------------------------------------------------------------------------------
# Creates a directory. Takes one mandatory argument:
# 
# 1. "${1:?}" - the directory to create.
# 
# Parent directories are created if required.
#-------------------------------------------------------------------------------
createDirectory () {
  local DIR="${1:?}"

  echoComment 'Creating directory at:'
  echoComment "$DIR"
  mkdir -p "$DIR"
}

#-------------------------------------------------------------------------------
# Creates one or more files. Takes one or more arguments:
# 
# 1. "$@" - one or more files to be created.
# 
# The function loops through each passed argument and creates each file.
#-------------------------------------------------------------------------------
createFiles () {
  for FILE in "$@"; do
    echoComment 'Creating file at:'
    echoComment "$FILE"
    touch "$FILE"

    echoSeparator
    listDirectories "$FILE"
    echoSeparator
    echoComment 'File created.'
  done
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

  echoComment "Performing $ACTION for $SERVICE."

  if [ "$SERVICE" = 'ufw' ]; then
    "$SERVICE" "$ACTION"
  else
    systemctl "$ACTION" "$SERVICE"
  fi
  
  echoComment "$ACTION performed for $SERVICE."
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
# Echose an "N.B." line for consistency.
#-------------------------------------------------------------------------------
echoNb () {
  echo "$COMMENT_PREFIX ****** N.B. ******"
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
# Generates a port number then checks against a given service. If the check
# returns true, re-run the function to generate a new port number. If the check 
# returns false, return the generated port number. Takes one mandatory argument:
# 
# 1. "{1:?}" – the service to check against.
#-------------------------------------------------------------------------------
generateAndCheckPort () {
  local CHECK_AGAINST="${1:?}"
  local PORT_NO="$(generatePortNumber)"
  local PORT_TF="$(checkAgainstExistingPortNumber "$PORT_NO" "$CHECK_AGAINST")"

  if [ "$PORT_TF" = true ]; then
    echoComment "Port check returned $PORT_TF. Re-running to generate" 
    echoComment 'another port number.'
    checkAndSetPort
  elif [ "$PORT_TF" = false ]; then
    echo "$PORT_NO"    
  fi
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

  echoComment 'Generating an ssh key at:' 
  echoComment "$KEY_PATH."
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

  echoComment 'Checking the setup config to see if this step has already been'
  echoComment 'performed…'
  echoComment "Check returned $CONFIG_KEY_TF."

  if [ "$CONFIG_KEY_TF" = true ]; then
    echoComment 'You have already performed this step.'
    echoScriptExiting

    exit 1
  elif [ "$CONFIG_KEY_TF" = false ]; then
    echoComment 'You have not performed this step. Running script.'
    echoSeparator
  else
    echoComment 'Something went wrong. Please check your setup config at:'
    echoComment "$SETUP_CONF."
    echoScriptExiting

    exit 1
  fi
}

#-------------------------------------------------------------------------------
# Installs or removes a given package. Takes at least two or more arguments:
# 
# 1. "${1:?}" - the action to be taken, either "install" or "remove"
# 2. "$i" – one or more packages to be installed.
# 
# The function tests to see if the an accepted value has been passed as the
# first argument then stores it as the action to be taken. It then shifts the 
# argument position by 1, and loops through each of the rest of the arguments. 
# As per:
# 
# https://unix.stackexchange.com/a/225951
#-------------------------------------------------------------------------------
installRemovePackages () {
  if [ "${1:?}" = 'install' -o "${1:?}" = 'remove' ]; then
    local ACTION="${1:?}"
  
    shift
  else
    echoComment "You must pass either install or remove as the first argument."
    echoScriptExiting
    
    exit 1
  fi

  for i; do
    echoComment "Performing $ACTION for $i."
    echoSeparator
    apt "$ACTION" "$i" -y
    echoSeparator
    echoComment "Completed $ACTION for $i"
  done
}

#-------------------------------------------------------------------------------
# Lists one or more directories. Takes one mandatory argument:
# 
# 1. "${1:?}" - a single directory path, or a list of multiple directory paths
#    separated by spaces.
# 
# N.B.
# "$DIR" is not quoted as we explicitly want word splitting here.
#-------------------------------------------------------------------------------
listDirectories () {
  local DIRS=${1:?}

  for DIR in $DIRS; do
    echoComment 'Listing directory:'
    echoSeparator
    ls -lna "$DIR"
    echoSeparator
  done
}

#-------------------------------------------------------------------------------
# Reads and returns the IP address of the host machine.
#-------------------------------------------------------------------------------
readIPAddress () {
  ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+'
}

#-------------------------------------------------------------------------------
# Reads and returns a setup config option. Takes one mandatory argument:
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
# Checks for, then adds, an environment variable to "$PROFILE". Takes two
# mandatory arguments:
# 
# 1. "{1:?}" - the name of the environment variable; and
# 2. "{2:?}" - the value of the environment variable.
# 
# If the variable is already in "$PROFILE" no changes are made. If the variable
# is not present in "$PROFILE" it is added.
# 
# Variables are added as per:
# 
# https://askubuntu.com/a/211718
# 
# N.B.
# For the shell to pick this up it requires the user to log out and back in.
#-------------------------------------------------------------------------------
setHostEnvVariable () {
  local ENV_VARIABLE="${1:?}"
  local ENV_VALUE="${2:?}"
  local ENV_TF="$(checkForHostEnvVariable "$ENV_VARIABLE")"
  local EXPORT="export $ENV_VARIABLE=$ENV_VALUE"

  if [ "$ENV_TF" = true ]; then
    echoComment "Already added $ENV_VARIABLE. No changes made."
  elif [ "$ENV_TF" = false ]; then
    echoComment "Adding $ENV_VARIABLE=$ENV_VALUE to:"
    echoComment "$PROFILE"
    echo "$EXPORT" >> "$PROFILE"

    echoComment 'Checking value added.'
    echoSeparator
    grep "$ENV_VARIABLE" "$PROFILE"
    echoSeparator
    echoComment "$ENV_VARIABLE added."

    echoSeparator
    echoComment 'This variable will not be recognised unti you log out and back in.'
  fi
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

  echoComment "Setting permissions of:"
  echoComment "$FILE_FOLDER"
  echoComment "to $PERMISSIONS."
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

  echoComment "Setting ownership of:"
  echoComment "$FILE_FOLDER"
  echoComment "to $USER:$GROUP."
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
  echoComment 'Packages updated and upgraded.'
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

  echoComment "Writing $CONF_KEY to:"
  echoComment "$SETUP_CONF"
  echo "$CONF_KEY $CONF_VALUE" >> "$SETUP_CONF"
  echoComment 'Config written.'

  setOwner "$SUDO_USER" "$SETUP_CONF"
}