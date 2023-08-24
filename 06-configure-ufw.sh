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
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredUfw'
SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" "lower")"

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
  echoComment 'Reading ssh port.'
  local SSH_PORT="$(readSetupConfigOption sshPort)"
  echoComment "Current port is $SSH_PORT."
  addRuleToUfw 'allow' "$SSH_PORT" 'tcp'
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  checkForServiceAndInstall "$SERVICE"

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