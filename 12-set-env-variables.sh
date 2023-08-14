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
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  local IP_ADDRESS="$(getIPAddress)"
  local TIMEZONE="$(timedatectl show | grep "Timezone")"
  local HOSTNAME="$(hostname)"
  local SUBDOMAIN="$(echo "$HOSTNAME" | cut -d'.' -f1)"
  local DOMAIN="${HOSTNAME#$SUBDOMAIN}"

  setEnvVariable "HOST_IP_ADDRESS" "$IP_ADDRESS"
  setEnvVariable "HOST_TIMEZONE" "$TIMEZONE" 
  setEnvVariable "HOST_DOMAIN" "$DOMAIN"
  setEnvVariable "HOST_SUBDOMAIN" "$SUBDOMAIN"

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