#!/bin/sh

#-------------------------------------------------------------------------------
# Initialises the setup by:
#
# 1. updating and upgrading packages; and
# 2. creating a config folder and file at "~/.config/linux-setup.conf".
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
. ./linshafun/host-information.sh
. ./linshafun/host-initialisation.sh
# . ./linshafun/initialisation.sh
# . ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
. ./linshafun/packages.sh
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
CONFIG_KEY='initialisedSetup'

#-------------------------------------------------------------------------------
# Reorders setup scripts based on whether the host machine is a Raspberry Pi or 
# not. If the host machine is a Pi, the script order is preserved. If not, 
# "02-configure-pi-specific-settings.sh" is removed and subsequent scripts are
# renamed.
#
# Returns 1 as soon as a script can't be removed or renamed. The linshafun
# functions print the error.
#-------------------------------------------------------------------------------
initialiseSetupScripts () {
  if checkIfRaspberryPi; then
    return 0
  fi

  removeFilesOrDirectories "./02-configure-pi-specific-settings.sh" || return 1
  renameFileOrDirectory "./03-change-password.sh" "./02-change-password.sh" || return 1
  renameFileOrDirectory "./04-change-username.sh" "./03-change-username.sh" || return 1
  renameFileOrDirectory "./05-setup-ssh-key.sh" "./04-setup-ssh-key.sh" || return 1
  renameFileOrDirectory "./06-configure-sshd.sh" "./05-configure-sshd.sh" || return 1
  renameFileOrDirectory "./07-configure-ufw.sh" "./06-configure-ufw.sh" || return 1
  renameFileOrDirectory "./08-configure-fail2ban.sh" "./07-configure-fail2ban.sh" || return 1
  renameFileOrDirectory "./09-configure-hostname.sh" "./08-configure-hostname.sh" || return 1
  renameFileOrDirectory "./10-configure-timezone.sh" "./09-configure-timezone.sh" || return 1
  renameFileOrDirectory "./11-configure-git.sh" "./10-configure-git.sh" || return 1
  renameFileOrDirectory "./12-configure-docker.sh" "./11-configure-docker.sh" || return 1
  renameFileOrDirectory "./13-set-env-variables.sh" "./12-set-env-variables.sh"
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script. Returns 1 as soon as a step fails.
#-------------------------------------------------------------------------------
mainScript () {
  updateAndUpgradePackages || return 1
  checkForAndCreateSetupConfigFileAndDir || return 1

  initialiseSetupScripts
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
