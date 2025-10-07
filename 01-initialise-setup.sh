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
. ./linshafun/comments.sh
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
# . ./linshafun/host-initialisation.sh
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
# not. If the host machine is a Pi, the scropt order is preserved. If not, 
# "02-configure-pi-specific-settings.sh" is removed and subsequent scripts are 
# renamed.
#-------------------------------------------------------------------------------
initialiseSetupScripts () {
  local IS_PI_TF="$(checkIfRaspberryPi)"

  if [ "$IS_PI_TF" = false ]; then
    rm "./02-configure-pi-specific-settings.sh"
    mv "./03-change-password.sh" "./02-change-password.sh"
    mv "./04-change-username.sh" "./03-change-username.sh"
    mv "./05-setup-ssh-key.sh" "./04-setup-ssh-key.sh"
    mv "./06-configure-sshd.sh" "./05-configure-sshd.sh"
    mv "./07-configure-ufw.sh" "./06-configure-ufw.sh"
    mv "./08-configure-fail2ban.sh" "./07-configure-fail2ban.sh"
    mv "./09-configure-hostname.sh" "./08-configure-hostname.sh"
    mv "./10-configure-timezone.sh" "./09-configure-timezone.sh"
    mv "./11-configure-git.sh" "./10-configure-git.sh"
    mv "./12-configure-docker.sh" "./11-configure-docker.sh"
    mv "./13-set-env-variables.sh" "./12-set-env-variables.sh"
  fi
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  updateUpgrade
  checkForAndCreateSetupConfigFileAndDir

  initialiseSetupScripts
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"