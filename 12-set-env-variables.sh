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
# - https://dev.to/natterstefan/docker-tip-how-to-get-host-s-ip-address-inside-a-docker-container-5anh
# 
# N.B. 
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported shared variables.
#-------------------------------------------------------------------------------
. ./linshafun/linshafun.var

#-------------------------------------------------------------------------------
# Imported project specific variables.
#-------------------------------------------------------------------------------
. ./linux-setup.var

#-------------------------------------------------------------------------------
# Imported shared functions.
#-------------------------------------------------------------------------------
. ./linshafun/comments.sh
# . ./linshafun/crontab.sh
# . ./linshafun/docker-env-variables.sh
# . ./linshafun/docker-images.sh
# . ./linshafun/docker-secrets.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/docker-volumes.sh
# . ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
. ./linshafun/host-env-variables.sh
# . ./linshafun/host-information.sh
# . ./linshafun/initialisation.sh
. ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-config.sh
# . ./linshafun/ssh-keys.sh
# . ./linshafun/text.sh
# . ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='setHostEnvVariables'

#-------------------------------------------------------------------------------
# Environment variable values. Set as follows:
#
# - "HOST_IP_ADDRESS" - using the "readIPAddress" function.
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
IP_ADDRESS="$(readIpAddress)"
TIMEZONE="$(timedatectl show | grep "Timezone" | cut -d'=' -f2)"
HOSTNAME="$(hostname)"
SUBDOMAIN="$(echo "$HOSTNAME" | cut -d'.' -f1)"
DOMAIN="${HOSTNAME#"$SUBDOMAIN".}"

#-------------------------------------------------------------------------------
# Check for the "@includedir" line in "$SUDOERS". If it is present, confirm it's
# present. If not present, add it at the end of the file, as per:
# 
# - https://stackoverflow.com/a/28382838
# 
# N.B.
# If the check returns anything other than true or false, the script exits with
# an error.
#-------------------------------------------------------------------------------
checkSudoersConf () {
  if grep -q "@includedir" "$SUDOERS_PATH"; then
    local INCLUDES_TF=true
  else
    local INCLUDES_TF=false
  fi

  printCheckResult "for include line in $SUDOERS_PATH" "$INCLUDES_TF"

  if [ "$INCLUDES_TF" = true ]; then
    printComment "Include line already present."   
  elif [ "$INCLUDES_TF" = false ]; then
    printComment 'Include line not present so adding it. You may be asked for your password.' 'warning'

    echo "@includedir $SUDOERS_CONF_DIR_PATH" | sudo EDITOR='tee -a' visudo

    printComment "Added include line."
    printSeparator
    grep "@includedir" "$SUDOERS_PATH"
    printSeparator

    setPermissions "440" "$SUDOERS_PATH"
  fi
}

#-------------------------------------------------------------------------------
# Creates the default environment config file for sudoers. As per:
# 
# - https://stackoverflow.com/a/8636711
#-------------------------------------------------------------------------------
createSudoersDefaultConf () {
  printComment 'Generating sudoers config file at:'
  printComment "$SUDOERS_DEFAULT_CONF_PATH"
  cat <<EOF > "$SUDOERS_DEFAULT_CONF_PATH"
Defaults env_keep += "HOST_IP_ADDRESS"
Defaults env_keep += "HOST_TIMEZONE"
Defaults env_keep += "HOST_DOMAIN"
Defaults env_keep += "HOST_SUBDOMAIN"
EOF
  printComment 'Config file generated.'

  setOwner "$USER" "$SUDOERS_DEFAULT_CONF_PATH"
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
  createSudoersDefaultConf

  printSeparator
  printComment 'As stated above these variables will not be usable until you have logged out and back in.' 'warning'
  printSeparator
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"