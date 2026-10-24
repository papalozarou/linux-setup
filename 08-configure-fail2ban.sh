#!/bin/sh

#-------------------------------------------------------------------------------
# Install and configure fail2ban by:
# 
# 1. checking if fail2ban is installed, installs if not;
# 2. generating the hardened config file, using the ssh port from the setup
#    config file;
# 3. adjusting permissions of the config file;
# 4. restarting fail2ban so it loads the config; and
# 5. listing the current status of fail2ban.
# 
# The configuration is stored at:
# 
# /etc/fail2ban/jail.local
#
# N.B.
# We check for "fail2ban-server", not "fail2ban".
# 
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
. ./linshafun/packages.sh
. ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-config.sh
# . ./linshafun/ssh-keys.sh
. ./linshafun/text.sh
# . ./linshafun/user-input.sh

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
# Creates the hardened config file for fail2ban. This overrides the default 
# values stored in /etc/fail2ban/jail.conf.
#
# The "sshd" jail's port is set to the ssh port defined in
# "06-configure-sshd.sh". Returns 1 with an error if no port is recorded in the
# setup config file, or if the file can't be written.
#
# N.B.
# fail2ban's own "sshd" jail uses "port = ssh", i.e. 22, and only bans on that
# port. ufw already denies port 22, so without this the bans would have no
# effect on the port sshd actually uses.
#-------------------------------------------------------------------------------
createHardenedFail2banConfig () {
  local SSH_PORT="$(readSetupConfigValue sshPort)"

  if [ -z "$SSH_PORT" ]; then
    printComment --error 'No ssh port found in the setup config file. Run the sshd script first.'

    return 1
  fi

  printComment "Generating fail2ban config file at $FAIL2BAN_DEFAULT_CONF."

  if ! cat <<EOF > "$FAIL2BAN_DEFAULT_CONF"; then
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 10m
findtime = 5m
maxretry = 3

[sshd]
enabled	= true
port	= $SSH_PORT
EOF
    printComment --error "Failed to write the fail2ban config file at $FAIL2BAN_DEFAULT_CONF."

    return 1
  fi

  printComment 'Config file generated.'
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script. Returns 1 as soon as a step fails.
#
# N.B.
# fail2ban is restarted rather than started. Installing the package starts it,
# and starting a service that is already running doesn't load the new config.
#-------------------------------------------------------------------------------
mainScript () {
  checkForPackagesAndInstall "$SERVICE" || return 1

  createHardenedFail2banConfig || return 1
  setPermissions '644' "$FAIL2BAN_DEFAULT_CONF" || return 1

  controlService 'restart' "$SERVICE" || return 1

  controlService 'status' "$SERVICE"
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
