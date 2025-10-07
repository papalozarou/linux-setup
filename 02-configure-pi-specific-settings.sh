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
CONFIG_KEY='configurePiSpecificSettings'

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
#-------------------------------------------------------------------------------
configurePiSettings () {
  local MODEL="$(getRaspberryPiModel)"

  printComment 'Configuring Raspberry Pi specific settings.'

  addPiVideoModesToCmdline
  addPiCgroupOptionsToCmdline

  if [ "$MODEL" -ge 4 ]; then
    updatePiFirmware
    updatePiBootloader

    setPiPowerOffOnHalt
  elif [ "$MODEL" -ge 5 ]; then
    enablePiPcieGen3InConfigTxt
  fi

  promptForUserInput "Do you want to disable the Raspberry Pi's onboard WiFi (y/n)?"
  local DISABLE_WIFI_YN="$(getUserInputYN)"

  if [ "$DISABLE_WIFI_YN" = true ]; then
    disablePiWifiInConfigTxt
  fi

  if [ "$MODEL" -ge 4 ]; then
    promptForUserInput "Do you want to disable the Raspberry Pi's onboard LEDs (y/n)?"
    local DISABLE_LEDS_YN="$(getUserInputYN)"
  fi

  if [ "$DISABLE_LEDS_YN" = true ]; then
    disablePiLedsInConfigTxt
  fi
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  local UPDATED_PI_FIRMWARE_TF="$(readSetupConfigValue 'addedPiVideoModes')"
  
  if [ -z "$UPDATED_PI_FIRMWARE_TF" ]; then
    configurePiSettings

    printComment 'To enable the changes made the system must be rebooted.' 'warning'
    printComment 'Once the system has rebooted, run this script again to complete the Pi specific setup.' 'warning'
    rebootSystem '20'
  else
    local REBOOT_TF="$(checkIfSystemRebooted)"
    printCheckResult 'for a recent reboot' "$REBOOT_TF"
  fi

  if [ "$REBOOT_TF" = true ]; then   
    printComment 'Raspberry Pi specific setup complete.'
  else
    printComment 'The system must be rebooted for changes to take effect.' 'warning'
    rebootSystem '20'
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"
