#!/bin/sh

#-------------------------------------------------------------------------------
# Install and configure docker by:
# 
# 1. checking if docker is installed, installs if not;
# 
#
# N.B.
# We check for "fail2ban-server", not "fail2ban".
# 
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

installDockerDependencies () {
  echoComment "Installing dependencies for $SERVICE."
  echoSeparator
  apt install ca-certificates \
              curl \
              gnupg
  echoSeparator
}

installDockerGpgKey () {
  echoComment "Adding official GPG key for $SERVICE."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
}

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
    updateUpgrade

    installDockerDependencies
    installDockerGpgKey
    installDockerRepository

    updateUpgrade

    installService "docker-ce \
              docker-ce-cli \
              containerd.io \
              docker-buildx-plugin \
              docker-compose-plugin"
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"
