#!/bin/sh

#-------------------------------------------------------------------------------
# Adds the host IP address as an environment variable, "EXTERNAL_IP_ADDRESS", by:
#
# 1. getting the IP address; and
# 2. writing it to either ".bashrc", ".bash_profile" or ".profile".
# 
# This variable is then used in later scripts and in Docker ".env" files when 
# building images. As per:
# 
# https://dev.to/natterstefan/docker-tip-how-to-get-host-s-ip-address-inside-a-docker-container-5anh
# 
# N.B.
# For the shell to pick this up it requires the user to log out and back in,
# which is done as part of "04-change-username.sh".
# 
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='setIpEnvVariable'

#-------------------------------------------------------------------------------
# File variables.
#-------------------------------------------------------------------------------
PROFILE="$(find "$USER_DIR" -type f \( -name ".bashrc" -o -name ".bash_profile" -o -name ".profile" \))"

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  local IP_ADDRESS="$(getIPAddress)"
  local EXPORT="export EXTERNAL_IP_ADDRESS=$IP_ADDRESS"

  echoComment "Adding external IP address $IP_ADDRESS to:"
  echoComment "$PROFILE"
  echo "$EXPORT" >> "$FILE"
  
  echoComment 'Checking value added.'
  echoSeparator
  grep "$IP_ADDRESS" "$PROFILE"
  echoSeparator
  echoComment 'IP address added'

  setPermissions 644 "$PROFILE"
  setOwner "$SUDO_UID" "$PROFILE"

  echoSeparator
  echoComment 'This variable will not be recognised until you log out and back in,'
  echoComment 'which is done as part of step 4 when changing your username.'
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"