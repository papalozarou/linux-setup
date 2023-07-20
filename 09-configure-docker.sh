#!/bin/sh

#-------------------------------------------------------------------------------
# Install and configure "docker" by:
#
# 1. installing dependencies;
# 2. adding the official GPG key for "docker";
# 3. adding the official docker repository; and
# 4. installing docker.
#
# N.B. 
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredDocker'
SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" "lower")"

#-------------------------------------------------------------------------------
# Installs the dependencies necessary to run Docker.
#
# N.B.
# Some of the dependencies may already be installed.
#-------------------------------------------------------------------------------
installDockerDependencies () {
  echoComment "Installing dependencies for $SERVICE."
  echoSeparator
  apt install 
  echoSeparator
}

#-------------------------------------------------------------------------------
# Adds the GPG key for Docker.
#-------------------------------------------------------------------------------
installDockerGpgKey () {
  echoComment "Adding official GPG key for $SERVICE."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
}

#-------------------------------------------------------------------------------
# Sets up the repository for Docker to enable install via "apt install".
#-------------------------------------------------------------------------------
installDockerRepository () {
  echoComment "Setting up the repository for $SERVICE."
  echoSeparator
  echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  echoSeparator
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  echoComment "Starting setup of $SERVICE."

  local SERVICE_CHECK="$(checkForService "$SERVICE")"
  echoComment "Checking for $SERVICE."
  echoComment "Check returned $SERVICE_CHECK."

  if [ "$SERVICE_CHECK" = true ]; then
    echoComment "You have already installed $SERVICE."
    echoScriptExiting

    exit 1
  elif [ "$SERVICE_CHECK" = false ]; then
    echoComment "You need to install $SERVICE."

    echoComment "Installing dependencies for $SERVICE."
    updateUpgrade
    installService "ca-certificates" "curl" "gnupg"

    installDockerGpgKey
    installDockerRepository

    updateUpgrade
    installService "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"
