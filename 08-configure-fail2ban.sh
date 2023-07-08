#!/bin/sh

#-------------------------------------------------------------------------------
# Install and configure fail2ban by:
# 
# 1. checking if fail2ban is installed, installs if not;
# 2. generating the hardened config file;
# 3. adjusting permissions of the config file;
# 4. starting fail2ban; and
# 5. listing the current status of fail2ban.
# 
# The configuration is stored at:
# 
# /etc/fail2ban/jail.local
#
# N.B.
# We check for `fail2ban-server`, not `fail2ban`.
# 
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredFail2ban'
SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" "lower")"

#-------------------------------------------------------------------------------
# fail2ban related variables.
#-------------------------------------------------------------------------------
GLOBAL_FAIL2BAN_DIR='/etc/fail2ban'
FAIL2BAN_DEFAULT_CONF="$GLOBAL_FAIL2BAN_DIR/jail.local"

#-------------------------------------------------------------------------------
# Creates the hardened config file for fail2ban. This overides the default 
# values stored in /etc/fail2ban/jail.conf.
#-------------------------------------------------------------------------------
createHardenedFail2banConfig () {
  echoComment "Generating fail2ban config file at $FAIL2BAN_DEFAULT_CONF."
  cat <<EOF > "$FAIL2BAN_DEFAULT_CONF"
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 10m
findtime = 5m
maxretry = 3

[sshd]
enabled	= true
EOF
  echoComment 'Config file generated.'
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  checkForServiceAndInstall "$SERVICE"

  createHardenedFail2banConfig
  setPermissions '644' "$FAIL2BAN_DEFAULT_CONF"

  controlService 'start' "$SERVICE"

  controlService 'status' "$SERVICE"
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"
