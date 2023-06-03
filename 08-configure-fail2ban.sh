#!/bin/sh

#-------------------------------------------------------------------------------
# Install and configure fail2ban. The configuration is stored at
# /etc/fail2ban/jail.local
#
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# fail2ban related variables.
#-------------------------------------------------------------------------------
GLOBAL_FAIL2BAN_DIR=/etc/fail2ban
FAIL2BAN_DEFAULT_CONF=$GLOBAL_FAIL2BAN_DIR/jail.local

#-------------------------------------------------------------------------------
# Creates the hardened config file for fail2ban. This overides the default 
# values stored in /etc/fail2ban/jail.conf.
#-------------------------------------------------------------------------------
createHardenedFail2banConfig () {
  echo "$COMMENT_PREFIX"'Generating fail2ban config file at '"$FAIL2BAN_DEFAULT_CONF"'.'
  cat <<EOF > $FAIL2BAN_DEFAULT_CONF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 10m
findtime = 5m
maxretry = 3

[sshd]
enabled	= true
EOF
  echo "$COMMENT_PREFIX"'Config file generated.'
}

#-------------------------------------------------------------------------------
# Runs if this step hasn't been completed before. The script:
#
# 1. checks if fail2ban is installed, installs if not;
# 2. generates the hardened config file;
# 3. adjusts permissions of the config file;
# 4. starts fail2ban; and
# 5. lists the current status of fail2ban.
# 
# N.B.
# We check for `fail2ban-server`, not `fail2ban`.
#-------------------------------------------------------------------------------
runScript () {
  local SERVICE='fail2ban'

  checkForServiceAndInstall $SERVICE

  createHardenedFail2banConfig
  setPermissions 644 $FAIL2BAN_DEFAULT_CONF

  controlService start $SERVICE

  controlService status $SERVICE

  writeSetupConfigOption configuredFail2ban true

  echoScriptFinished "setting up $SERVICE."
}

#-------------------------------------------------------------------------------
# Performas the initial check to see if this step has already been completed.
#-------------------------------------------------------------------------------
initialiseScript configuredFail2ban
