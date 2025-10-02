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
# . ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='initialisedSetup'

#-------------------------------------------------------------------------------
# Initialises Raspberry Pi specific settings by:
# 
# - updating the firmware and bootloader on Pi models 4 and later;
# - adding video modes and cgroup memory options to "cmdline.txt";
# - setting "POWER_OFF_ON_HALT=1" for Pi models 4 and later;
# - optionally disabling onboard WiFi;
# - optionally disabling onboard LEDs on Pi models 4 and later; and
# - enabling PCIe Gen 3 for Pi models 5 and later.
#-------------------------------------------------------------------------------
initialisePi () {
  printComment 'Initialising Raspberry Pi specific settings.'

  promptForUserInput "Do you want to disable the Raspberry Pi's onboard LEDs (y/n)?"
  local DISABLE_LEDS_YN="$(getUserInputYN)"

  updatePiFirmware
  updatePiBootloader

  addPiVideoModesToCmdline
  addPiCgroupOptionsToCmdline

  setPiPowerOffOnHalt

  promptForUserInput "Do you want to disable the Raspberry Pi's onboard WiFi (y/n)?"
  local DISABLE_WIFI_YN="$(getUserInputYN)"

  if [ "$DISABLE_WIFI_YN" = true ]; then
    disablePiWifiInConfigTxt
  fi

  promptForUserInput "Do you want to disable the Raspberry Pi's onboard LEDs (y/n)?"
  local DISABLE_LEDS_YN="$(getUserInputYN)"

  if [ "$DISABLE_LEDS_YN" = true ]; then
    disablePiOnboardLeds
  fi

  enablePiPcieGen3InConfigTxt
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  local IS_PI_TF="$(checkIfRaspberryPi)"

  updateUpgrade
  checkForAndCreateSetupConfigFileAndDir

  if [ "$IS_PI_TF" = true ]; then
    initialisePi
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"