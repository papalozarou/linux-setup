#!/bin/sh

#-------------------------------------------------------------------------------
# Installs and configures ufw by:
# 
# 1. checking if ufw is installed, installs if not;
# 2. explicitly denying incoming traffic;
# 3. explicitly allowing outgoing traffic;
# 4. denying all traffic on port 22;
# 5. adding the "$SSH_PORT" configured in the previous step;
# 6. enabling ufw; and
# 7. listing the current ufw configuration.
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
# . ./linshafun/docker-env-variables.sh
# . ./linshafun/docker-images.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/files-directories.sh
. ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
. ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
. ./linshafun/packages.sh
. ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-keys.sh
. ./linshafun/text.sh
# . ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredUfw'
SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" "lower")"

#-------------------------------------------------------------------------------
# Disables IPv6 rules in ufw.
#-------------------------------------------------------------------------------
setIpv6No () {
  local UFW_CONF='/etc/default/ufw'

  echoComment 'Turning off IPv6 rules in:'
  echoComment "$UFW_CONF"
  sed -i '/IPV6=/c\\IPV6=no' "$UFW_CONF"

  echoSeparator
  grep 'IPV6=' "$UFW_CONF"
  echoSeparator
  echoComment 'IPv6 turned off.'
}

#-------------------------------------------------------------------------------
# Adds a default set of ufw rules, by:
#
# 1. denying all incoming traffic;
# 2. allowing all outgoing traffic; and
# 3. denying port 22 explicitly.
# 
# N.B.
# The first two rules are set without using the "addRuleToUfw" function as
# the function needs re-writing to allow for "default" rules with no port.
#-------------------------------------------------------------------------------
setUfwDefaults () {
  "$SERVICE" default deny incoming
  "$SERVICE" default allow outgoing
  addRuleToUfw 'deny' '22'
}

#-------------------------------------------------------------------------------
# Adds the ssh port defined in "06-configure-sshd.sh" to ufw.
#-------------------------------------------------------------------------------
allowSshPort () {
  local SSH_PORT="$(readSetupConfigValue sshPort)"
  
  echoComment 'Reading ssh port.'
  echoComment "Current port is $SSH_PORT."
  addRuleToUfw 'allow' "$SSH_PORT" 'tcp'
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  checkForPackagesAndInstall "$SERVICE"

  setIpv6No

  setUfwDefaults
  allowSshPort  

  controlService 'enable' "$SERVICE"

  listUfwRules
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"