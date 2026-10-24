#!/bin/sh

#-------------------------------------------------------------------------------
# Configures Raspberry Pi specific settings by:
#
# - updating the firmware and bootloader on Pi models 4 and later;
# - adding video modes and cgroup memory options to "cmdline.txt";
# - setting "POWER_OFF_ON_HALT=1" for Pi models 4 and later;
# - optionally disabling onboard WiFi;
# - optionally disabling onboard LEDs on Pi models 4 and later; and
# - enabling PCIe Gen 3 for Pi models 5 and later.
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
CONFIG_KEY='configuredPiSpecificSettings'

#-------------------------------------------------------------------------------
# Configures Raspberry Pi specific settings by:
#
# - checking the Pi model;
# - updating the firmware and bootloader on Pi models 4 and later;
# - adding video modes and cgroup memory options to "cmdline.txt";
# - setting "POWER_OFF_ON_HALT=1" for Pi models 4 and later;
# - optionally disabling onboard WiFi;
# - optionally disabling onboard LEDs on Pi models 4 and later; and
# - enabling PCIe Gen 3 for Pi models 5 and later.
#
# Once every step has succeeded, "appliedPiSettings true" is written to the
# setup config file. Returns 1 as soon as a step fails, without writing it, so
# the next run starts the settings again. The linshafun functions print the
# error, and skip changes already made to "cmdline.txt" and "config.txt".
#
# N.B.
# "getRaspberryPiModel" returns an empty string for models without a number,
# e.g. "Raspberry Pi Zero 2 W", so "0" is used to skip the Pi 4 and 5 steps
# without an "integer expression expected" error.
#-------------------------------------------------------------------------------
configurePiSettings () {
  local MODEL="$(getRaspberryPiModel)"
  local DISABLE_WIFI_YN=false
  local DISABLE_LEDS_YN=false

  MODEL="${MODEL:-0}"

  printComment 'Configuring Raspberry Pi specific settings.'

  addPiVideoModesToCmdline || return 1
  addPiCgroupOptionsToCmdline || return 1

  if [ "$MODEL" -ge 4 ]; then
    updatePiFirmware || return 1
    updatePiBootloader || return 1

    setPiPowerOffOnHalt || return 1
  fi

  if [ "$MODEL" -ge 5 ]; then
    enablePiPcieGen3InConfigTxt || return 1
  fi

  promptForUserInput "Do you want to disable the Raspberry Pi's onboard WiFi (y/n)?"
  if getUserInputYN; then DISABLE_WIFI_YN=true; fi

  if [ "$DISABLE_WIFI_YN" = true ]; then
    disablePiWifiInConfigTxt || return 1
  fi

  if [ "$MODEL" -ge 4 ]; then
    promptForUserInput "Do you want to disable the Raspberry Pi's onboard LEDs (y/n)?"
    getUserInputYN && DISABLE_LEDS_YN=true
  fi

  if [ "$DISABLE_LEDS_YN" = true ]; then
    disablePiLedsInConfigTxt || return 1
  fi

  writeSetupConfigOption 'appliedPiSettings' 'true'
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script. The script is run twice:
#
# 1. the first run applies the settings, then reboots; and
# 2. the second run, once "appliedPiSettings" is in the setup config file,
#    checks the system rebooted in the last 300 seconds, and reboots again if
#    not.
#
# Returns 1 if the settings can't be applied. "rebootSystem" exits the script
# with 0, so "finaliseScript" only runs after a recent reboot.
#-------------------------------------------------------------------------------
mainScript () {
  local APPLIED_PI_SETTINGS_TF="$(readSetupConfigValue 'appliedPiSettings')"

  if [ -z "$APPLIED_PI_SETTINGS_TF" ]; then
    configurePiSettings || return 1

    printComment --warning 'To enable the changes made the system must be rebooted.'
    printComment --warning 'Once the system has rebooted, run this script again to complete the Pi specific setup.'
    rebootSystem '20'
  fi

  printComment 'Checking for a recent reboot.'

  if checkIfSystemRebooted '300'; then
    printComment 'Raspberry Pi specific setup complete.'

    return 0
  fi

  printComment --warning 'The system must be rebooted for changes to take effect.'
  rebootSystem '20'
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
