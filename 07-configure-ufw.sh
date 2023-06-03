#!/bin/sh

#-------------------------------------------------------------------------------
# Install and configure ufw to only accept traffic on required ports for ssh.
#
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Runs if this step hasn't been completed before. The script:
#
# 1. checks if ufw is installed, installs if not;
# 2. denies incoming traffic;
# 3. allows outgoing traffic;
# 4. denies all traffic on port 22;
# 5. adds the ssh port configured in the previous step;
# 6. enables ufw; and
# 7. lists the current ufw configuration.
#-------------------------------------------------------------------------------
runScript () {
  local SERVICE='ufw'
  checkForServiceAndInstall $SERVICE

  echo "$COMMENT_PREFIX"'Explicitly denying incoming traffic.'
  echo "$COMMENT_SEPARATOR"
  $SERVICE default deny incoming
  echo "$COMMENT_SEPARATOR"

  echo "$COMMENT_PREFIX"'Explicitly allowing outgoing traffic.'
  echo "$COMMENT_SEPARATOR"
  $SERVICE default allow outgoing
  echo "$COMMENT_SEPARATOR"

  echo "$COMMENT_PREFIX"'Explicitly denying port 22.'
  echo "$COMMENT_SEPARATOR"
  addRuleToUfw deny 22
  echo "$COMMENT_SEPARATOR"
  
  echo "$COMMENT_PREFIX"'Reading ssh port.'
  local SSH_PORT=$(readSetupConfigOption sshPort)
  echo "$COMMENT_PREFIX"'Current port is '"$SSH_PORT"'.'

  addRuleToUfw allow $SSH_PORT tcp

  controlService enable $SERVICE

  $SERVICE status numbered
  echo "$COMMENT_SEPARATOR"

  writeSetupConfigOption configuredUfw true

  echoScriptFinished "setting up $SERVICE"
}

#-------------------------------------------------------------------------------
# Performs the initial check to see if this step has already been completed.
#-------------------------------------------------------------------------------
initialiseScript configuredUfw