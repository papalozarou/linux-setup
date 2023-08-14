#!/bin/sh

#-------------------------------------------------------------------------------
# Sets a few environment variables for the current user, by:
#
# 1. setting the variables; and
# 2. adding "env_keep" values to "sudoers".
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
CONFIG_KEY='setHostEnvVariables'

#-------------------------------------------------------------------------------
# File and directory variables.
#-------------------------------------------------------------------------------
SUDOERS='/etc/sudoers'
SUDOERS_CONF_DIR="$SUDOERS.d"
SUDOERS_DEFAULT_CONF="$SUDOERS_CONF_DIR/99-default-env-keep"

#-------------------------------------------------------------------------------
# Environment variable values. Set as follows:
#
# - "HOST_IP_ADDRESS" - using the "getIPAddress" function.
# - "HOST_TIMEZONE" - grepping "Timezone" from the output of "timedatectl show".
# - "HOST_DOMAIN" - cutting "$HOSTNAME" using "." as a delimiter, and taking the 
#   first segment, "f1".
# - "HOST_SUBDOMAIN" - trimming "$SUBDOMAIN", with a trailing period, from
#   "$HOSTNAME"
# 
# Usage of cut and trim as per:
# 
# - cut - https://unix.stackexchange.com/a/312281
# - trim - https://stackoverflow.com/a/10520718
#-------------------------------------------------------------------------------
IP_ADDRESS="$(getIPAddress)"
TIMEZONE="$(timedatectl show | grep "Timezone" | cut -d'=' -f2)"
HOSTNAME="$(hostname)"
SUBDOMAIN="$(echo "$HOSTNAME" | cut -d'.' -f1)"
DOMAIN="${HOSTNAME#"$SUBDOMAIN".}"

#-------------------------------------------------------------------------------
# Check for the "@includedir" line in "$SUDOERS". If it is present, confirm it's
# present. If not present, add it at the end of the file, as per:
# 
# https://stackoverflow.com/a/28382838
#-------------------------------------------------------------------------------
checkSudoersConf () {
  echoComment 'Checking for include line in:'
  echoComment "$SUDOERS"

  local INCLUDES="$(grep "@includedir" "$SUDOERS")"

  if [ -z "$INCLUDES" ]; then
    echoComment 'Include line not present so adding it. You may be asked for'
    echoComment 'your password.'

    echo "@includedir $SUDOERS_CONF_DIR" | sudo EDITOR='tee -a' visudo

    echoComment "Added include line."
    echoSeparator
    grep "@includedir" "$SUDOERS"
    echoSeparator
  else
    echoComment "Include line already present."
  fi
}

#-------------------------------------------------------------------------------
# Creates the default environment config file for sudoers. As per:
# 
# https://stackoverflow.com/a/8636711
#-------------------------------------------------------------------------------
createSudoersConf () {
  echoComment 'Generating sudoers config file at:'
  echoComment "$SUDOERS_DEFAULT_CONF"
  cat <<EOF > "$SUDOERS_DEFAULT_CONF"
Defaults env_keep += "HOST_IP_ADDRESS"
Defaults env_keep += "HOST_TIMEZONE"
Defaults env_keep += "HOST_DOMAIN"
Defaults env_keep += "HOST_SUBDOMAIN"
EOF
  echoComment 'Config file generated.'
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  setHostEnvVariable "HOST_IP_ADDRESS" "$IP_ADDRESS"
  setHostEnvVariable "HOST_TIMEZONE" "$TIMEZONE" 
  setHostEnvVariable "HOST_DOMAIN" "$DOMAIN"
  setHostEnvVariable "HOST_SUBDOMAIN" "$SUBDOMAIN"

  checkSudoersConf
  createSudoersConf
  setPermissions "440" "$SUDOERS"
  setOwner "$USER" "$SUDOERS_DEFAULT_CONF"

  echoSeparator
  echoNb
  echoComment 'As stated above these variables will not be usable until you have'
  echoComment 'logged out and back in.'
  echoSeparator
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"