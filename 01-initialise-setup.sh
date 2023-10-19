#!/bin/sh

#-------------------------------------------------------------------------------
# Initialises the setup by:
#
# 1. updating and upgrading packages; and
# 2. creating a config file in "~/.config/linux-setup/setup.conf"
# 
# N.B.
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported variables.
#-------------------------------------------------------------------------------
. ./linshafun/docker.var
. ./linshafun/setup.var

#-------------------------------------------------------------------------------
# Imported shared functions.
#-------------------------------------------------------------------------------
. ./linshafun/comments.sh
. ./linshafun/files-directories.sh
. ./linshafun/packages.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='initialisedSetup'

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  updateUpgrade
  checkForSetupConfigDir
  checkForSetupConfigFile
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"