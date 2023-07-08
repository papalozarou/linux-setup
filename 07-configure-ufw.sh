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
# Runs the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  checkForServiceAndInstall "$SERVICE"

  addRuleToUfw 'default' 'deny incoming'
  addRuleToUfw 'default' 'allow outgoing'
  addRuleToUfw 'deny' '22'
  
  echoComment 'Reading ssh port.'
  local SSH_PORT=$(readSetupConfigOption sshPort)
  echoComment "Current port is $SSH_PORT."
  addRuleToUfw 'allow' "$SSH_PORT" 'tcp'

  controlService 'enable' "$SERVICE"

  echoSeparator
  "$SERVICE" status numbered
  echoSeparator
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"