#!/bin/sh

#-------------------------------------------------------------------------------
# Set the hostname, by:
#
# 1. checking the current hostname;
# 2. asking if the user wants to change it or create one if unset;
# 3. setting a hostname; and
# 4. updating the "127.0.1.1" line in "/etc/hosts" to the new hostname.
#
# Based on this RedHat guide:
#
# - https://www.redhat.com/sysadmin/configure-hostname-linux
#
# N.B.
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported shared variables.
#-------------------------------------------------------------------------------
. ./linshafun/linshafun.var
# . ./linshafun/linshafun-docker.var

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
# . ./linshafun/host-env-variables.sh
# . ./linshafun/host-information.sh
# . ./linshafun/host-initialisation.sh
# . ./linshafun/initialisation.sh
# . ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-config.sh
# . ./linshafun/ssh-keys.sh
. ./linshafun/text.sh
. ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredHostname'

#-------------------------------------------------------------------------------
# Asks the user to change the hostname. Runs "setNewHostname" if yes, makes no
# changes if no. Returns 1 if the hostname can't be changed.
#-------------------------------------------------------------------------------
changeHostname () {
  promptForUserInput 'Would you like to change the hostname (y/n)?'
  HOSTNAME_CHANGE_YN=false
  if getUserInputYN; then HOSTNAME_CHANGE_YN=true; fi

  if [ "$HOSTNAME_CHANGE_YN" = true ]; then
    setNewHostname
  else
    printComment 'No changes made to hostname.'
  fi
}

#-------------------------------------------------------------------------------
# Checks the existing hostname.
#-------------------------------------------------------------------------------
checkHostname () {
  local CURRENT_HOSTNAME="$(hostname)"

  if [ -z "$CURRENT_HOSTNAME" ]; then
    printComment --warning 'No hostname set.'
  else
    printComment 'The current hostname is:'
    printComment -- "$CURRENT_HOSTNAME"
  fi
}

#-------------------------------------------------------------------------------
# Sets a new user-inputted hostname, then updates "/etc/hosts" to match. The
# hostname "hostnamectl" actually set is used for "/etc/hosts", as it may
# change the input, e.g. by removing characters that aren't allowed.
# Returns 1 with an error if "hostnamectl" rejects the hostname, or if
# "/etc/hosts" can't be updated.
#-------------------------------------------------------------------------------
setNewHostname () {
  local NEW_HOSTNAME

  promptForUserInput 'What is your new hostname (my.hostname.com)?'
  NEW_HOSTNAME="$(getUserInput)"

  printComment 'Setting hostname to:'
  printComment -- "$NEW_HOSTNAME"
  printComment 'You may be asked to authenticate.'

  if ! hostnamectl set-hostname "$NEW_HOSTNAME"; then
    printComment --error "Failed to set the hostname to $NEW_HOSTNAME."

    return 1
  fi

  printComment 'Hostname is now set to:'
  hostname

  setHostsFileHostname "$(hostname)"
}

#-------------------------------------------------------------------------------
# Sets the hostname on the "127.0.1.1" line of "/etc/hosts", so the host can
# resolve its own name. Takes one mandatory argument:
#
# 1. "${1:?}" – the new hostname, e.g. "my.hostname.com".
#
# The line is replaced if it exists, or added if not. For a hostname with dots,
# the short name is added after it as an alias, e.g. "127.0.1.1 my.hostname.com
# my". The line format, the address, then the hostname, then any aliases, is
# described in:
#
# - https://man7.org/linux/man-pages/man5/hosts.5.html
# - https://www.debian.org/doc/manuals/debian-reference/ch05.en.html#_the_hostname_resolution
#
# Returns 1 with an error if the file can't be updated.
#
# N.B.
# Without this, the old hostname stays on the line, and "sudo" can print
# "unable to resolve host". On hosts where cloud-init manages "/etc/hosts", i.e.
# "manage_etc_hosts: true", cloud-init may overwrite this on the next boot.
#-------------------------------------------------------------------------------
setHostsFileHostname () {
  local HOSTNAME_VALUE="${1:?}"
  local SHORT_HOSTNAME="${HOSTNAME_VALUE%%.*}"
  local HOSTS_PATH='/etc/hosts'
  local HOSTS_LINE="127.0.1.1 $HOSTNAME_VALUE"
  local SEPARATOR="$(printf '\001')"
  local STATUS=0

  if [ "$SHORT_HOSTNAME" != "$HOSTNAME_VALUE" ]; then
    HOSTS_LINE="$HOSTS_LINE $SHORT_HOSTNAME"
  fi

  printComment 'Setting the hostname on the 127.0.1.1 line in:'
  printComment -- "$HOSTS_PATH"

  if grep -q '^127\.0\.1\.1[[:space:]]' "$HOSTS_PATH"; then
    sed -i "s${SEPARATOR}^127\.0\.1\.1[[:space:]].*${SEPARATOR}${HOSTS_LINE}${SEPARATOR}" "$HOSTS_PATH" || STATUS=1
  else
    printf '%s\n' "$HOSTS_LINE" >> "$HOSTS_PATH" || STATUS=1
  fi

  if [ "$STATUS" -ne 0 ] || ! grep -Fqx "$HOSTS_LINE" "$HOSTS_PATH"; then
    printComment --error "Failed to set the hostname in $HOSTS_PATH."

    return 1
  fi

  printSeparator
  grep '^127\.0\.1\.1' "$HOSTS_PATH"
  printSeparator
  printComment 'Hostname set in /etc/hosts.'
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script. Returns 1 if the hostname can't be
# changed.
#-------------------------------------------------------------------------------
mainScript () {
  checkHostname
  changeHostname
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
