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
. ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
# . ./linshafun/host-information.sh
# . ./linshafun/host-initialisation.sh
# . ./linshafun/initialisation.sh
. ./linshafun/network.sh
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
CONFIG_KEY='configuredUfw'
SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" "lower")"

#-------------------------------------------------------------------------------
# Turns on IPv6 rules in ufw, so the rules added by this script apply to IPv4
# and IPv6. Returns 1 with an error if "IPV6=yes" isn't set afterwards.
#
# N.B.
# This must run before any rules are added, as ufw only adds the IPv6 version
# of a rule when IPv6 rules are on. Without it, services listening on IPv6
# aren't filtered. sshd is unaffected, as "06-configure-sshd.sh" sets it to
# listen on IPv4 only.
#-------------------------------------------------------------------------------
setIpv6Yes () {
  local UFW_CONF='/etc/default/ufw'

  printComment 'Turning on IPv6 rules in:'
  printComment -- "$UFW_CONF"

  if ! sed -i 's/^IPV6=.*/IPV6=yes/' "$UFW_CONF" || ! grep -qx 'IPV6=yes' "$UFW_CONF"; then
    printComment --error "Failed to set IPV6=yes in $UFW_CONF."

    return 1
  fi

  printSeparator
  grep 'IPV6=' "$UFW_CONF"
  printSeparator
  printComment 'IPv6 turned on.'
}

#-------------------------------------------------------------------------------
# Adds a default set of ufw rules, by:
#
# 1. denying all incoming traffic;
# 2. allowing all outgoing traffic; and
# 3. denying port 22 explicitly.
#
# Returns 1 with an error as soon as a rule can't be set.
# 
# N.B.
# The first two rules are set without using the "addRuleToUfw" function as
# the function needs re-writing to allow for "default" rules with no port.
#-------------------------------------------------------------------------------
setUfwDefaults () {
  if ! "$SERVICE" default deny incoming || ! "$SERVICE" default allow outgoing; then
    printComment --error 'Failed to set the default ufw rules.'

    return 1
  fi

  addRuleToUfw 'deny' 'any' '22' 'any' 'Default SSH'
}

#-------------------------------------------------------------------------------
# Adds the ssh port defined in "06-configure-sshd.sh" to ufw. Returns 1 with an
# error if no port is recorded in the setup config file, or if the rule can't be
# added.
#-------------------------------------------------------------------------------
allowSshPort () {
  local SSH_PORT="$(readSetupConfigValue sshPort)"

  printComment 'Reading ssh port…'

  if [ -z "$SSH_PORT" ]; then
    printComment --error 'No ssh port found in the setup config file. Run the sshd script first.'

    return 1
  fi

  printComment "Current port is $SSH_PORT."
  addRuleToUfw 'allow' 'any' "$SSH_PORT" 'tcp' 'SSH'
}

#-------------------------------------------------------------------------------
# Enables ufw, then checks it's active. Returns 1 with an error if it isn't.
#
# N.B.
# When run over ssh, "ufw enable" asks "Command may disrupt existing ssh
# connections. Proceed with operation (y|n)?". If the answer isn't "y", ufw
# prints "Aborted" and exits with 0 without enabling the firewall, so the
# status is checked separately.
#-------------------------------------------------------------------------------
enableUfw () {
  controlService 'enable' "$SERVICE" || return 1

  if ! "$SERVICE" status | grep -q '^Status: active'; then
    printComment --error 'ufw is not active, so the firewall is off. Run this script again to enable it.'

    return 1
  fi
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script. Returns 1 as soon as a step fails, so
# ufw isn't enabled unless the ssh port rule has been added.
#-------------------------------------------------------------------------------
mainScript () {
  checkForPackagesAndInstall "$SERVICE" || return 1

  setIpv6Yes || return 1

  setUfwDefaults || return 1
  allowSshPort || return 1

  enableUfw || return 1

  listUfwRules
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
