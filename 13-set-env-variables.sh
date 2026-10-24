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
. ./linshafun/comments-logs.sh
# . ./linshafun/crontab.sh
# . ./linshafun/docker-env-variables.sh
# . ./linshafun/docker-images.sh
# . ./linshafun/docker-secrets.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/docker-volumes.sh
. ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
. ./linshafun/host-env-variables.sh
# . ./linshafun/host-information.sh
# . ./linshafun/host-initialisation.sh
# . ./linshafun/initialisation.sh
. ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-config.sh
# . ./linshafun/ssh-keys.sh
. ./linshafun/text.sh
# . ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='setHostEnvVariables'

#-------------------------------------------------------------------------------
# Environment variable values. Set as follows:
#
# - "HOST_IP_ADDRESS" - using the "readIpAddress" function.
# - "HOST_TIMEZONE" - grepping "Timezone" from the output of "timedatectl show".
# - "HOST_SUBDOMAIN" - cutting "$HOSTNAME" using "." as a delimiter, and taking
#   the first segment, "f1".
# - "HOST_DOMAIN" - trimming "$SUBDOMAIN", with a trailing period, from
#   "$HOSTNAME".
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
# Check for the include line in "$SUDOERS_PATH". If it is present, confirm it's
# present. If not present, add it at the end of the file, as per:
# 
# - https://stackoverflow.com/a/28382838
#
# Returns 1 with an error if the line can't be added.
#
# N.B.
# Older sudoers files, e.g. on Ubuntu 20.04, use "#includedir", and newer ones
# use "@includedir". Both include the directory, so either counts as present.
#-------------------------------------------------------------------------------
checkSudoersConf () {
  printComment 'Checking for the include line in the sudoers file.'

  if grep -Eq '^[#@]includedir' "$SUDOERS_PATH"; then
    printComment "Include line already present."

    return 0
  fi

  printComment --warning 'Include line not present so adding it. You may be asked for your password.'

  if ! echo "@includedir $SUDOERS_CONF_DIR_PATH" | sudo EDITOR='tee -a' visudo; then
    printComment --error "Failed to add the include line to $SUDOERS_PATH."

    return 1
  fi

  printComment "Added include line."
  printSeparator
  grep "@includedir" "$SUDOERS_PATH"
  printSeparator

  setPermissions "440" "$SUDOERS_PATH"
}

#-------------------------------------------------------------------------------
# Adds an "env_keep" line for each host environment variable to
# "$SUDOERS_DEFAULT_CONF_PATH", so "sudo" keeps them. Returns 1 if any line
# can't be added.
#
# N.B.
# "addHostEnvVariableToSudoersConf" checks each line with "visudo", skips lines
# already in the file, and sets the file's mode to "440".
#-------------------------------------------------------------------------------
addHostEnvVariablesToSudoersConf () {
  local STATUS=0
  local ENV_VAR

  printComment 'Adding env_keep lines to the sudoers config file at:'
  printComment -- "$SUDOERS_DEFAULT_CONF_PATH"

  for ENV_VAR in HOST_IP_ADDRESS HOST_TIMEZONE HOST_DOMAIN HOST_SUBDOMAIN; do
    addHostEnvVariableToSudoersConf "$ENV_VAR" || STATUS=1
  done

  return "$STATUS"
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script. Returns 1 as soon as a step fails.
#-------------------------------------------------------------------------------
mainScript () {
  setHostEnvVariable "HOST_IP_ADDRESS" "$IP_ADDRESS" || return 1
  setHostEnvVariable "HOST_TIMEZONE" "$TIMEZONE" || return 1
  setHostEnvVariable "HOST_DOMAIN" "$DOMAIN" || return 1
  setHostEnvVariable "HOST_SUBDOMAIN" "$SUBDOMAIN" || return 1

  checkSudoersConf || return 1
  addHostEnvVariablesToSudoersConf || return 1

  printSeparator
  printComment --warning 'As stated above these variables will not be usable until you have logged out and back in.'
  printSeparator
}

#-------------------------------------------------------------------------------
# Run the script. If "mainScript" fails, the script exits with 1 before
# "finaliseScript", so the step isn't recorded as done in the setup config file
# and can be run again.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"

if ! mainScript; then
  printScriptExiting --changes
  exit 1
fi

finaliseScript "$CONFIG_KEY"
