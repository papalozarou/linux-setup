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
createHardenedFail2BanConfig () {
  echo "$COMMENT_PREFIX"'Generating fail2ban config file at '"$FAIL2BAN_DEFAULT_CONF"'.'
  cat <<EOF > $FAIL2BAN_DEFAULT_CONF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 10m
findtime  = 5m
maxretry = 3

[sshd]
enabled	= true
EOF
  echo "$COMMENT_PREFIX"'Config file generated.'
}

#-------------------------------------------------------------------------------
# N.B.
# We check for fail2ban-server, not fail2ban.
#-------------------------------------------------------------------------------