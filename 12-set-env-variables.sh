#!/bin/sh

#-------------------------------------------------------------------------------
# Sets a few environment variables for use with docker projects:
#
# 1. "HOST_IP_ADDRESS"
# 2. "HOST_TIMEZONE"
# 3. "HOST_DOMAIN"
# 4. "HOST_SUBDOMAIN"
# 
# These variables can then be used in other projects and in Docker ".env" files
# when building images. As per:
# 
# https://dev.to/natterstefan/docker-tip-how-to-get-host-s-ip-address-inside-a-docker-container-5anh
# 
# N.B. 
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='setEnvVariables'

#-------------------------------------------------------------------------------
# Environment variable values.
#-------------------------------------------------------------------------------
IP_ADDRESS="$(getIPAddress)"
TIMEZONE="$(timedatectl show | grep "Timezone")"
HOSTNAME="$(hostname)"
SUBDOMAIN="$(echo "$HOSTNAME" | cut -d'.' -f1)"
DOMAIN="${HOSTNAME#$SUBDOMAIN}"

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  setEnvVariable "HOST_IP_ADDRESS" "$IP_ADDRESS"
  setEnvVariable "HOST_TIMEZONE" "$TIMEZONE" 
  setEnvVariable "HOST_DOMAIN" "$DOMAIN"
  setEnvVariable "HOST_SUBDOMAIN" "$SUBDOMAIN"

  setPermissions 644 "$PROFILE"
  setOwner "$SUDO_UID" "$PROFILE"

  echoSeparator
  echoComment '****** N.B. ******'
  echoComment 'As stated above these variables will not be usable until you have'
  echoComment 'logged out and back in.'
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"