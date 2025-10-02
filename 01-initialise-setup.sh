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
# . ./linshafun/text.sh
# . ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='initialisedSetup'

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  updateUpgrade
  checkForAndCreateSetupConfigFileAndDir
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"