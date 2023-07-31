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
# Installs all components of docker, after updating and upgrading packages to
# ensure use of the added docker repository.
#-------------------------------------------------------------------------------
installDocker () {
  echoComment "Installing $SERVICE."
  echoSeparator
  updateUpgrade
  installService "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
}

#-------------------------------------------------------------------------------
# Installs the dependencies necessary to run docker, after updating and 
# upgrading packages.
#
# N.B.
# Some of the dependencies may already be installed.
#-------------------------------------------------------------------------------
installDockerDependencies () {
  echoComment "Installing dependencies for $SERVICE."
  echoSeparator
  updateUpgrade
  installService "ca-certificates" "curl" "gnupg"
}

#-------------------------------------------------------------------------------
# Adds the GPG key for docker.
#-------------------------------------------------------------------------------
installDockerGpgKey () {
  echoComment "Adding official GPG key for $SERVICE."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
}

#-------------------------------------------------------------------------------
# Sets up the repository for docker to enable install via "apt install".
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
# Removes any existing install of docker.
#-------------------------------------------------------------------------------
removeExistingDocker () {
  echoComment "Removing any existing installation of $SERVICE."
  echoComment "N.B. This may show that none of these packages are installed."
  installRemovePackages "remove" "docker.io" "docker-doc" "docker-compose" "podman-docker" "containerd" "runc"
}

#-------------------------------------------------------------------------------
# Verifies that the docker install worked correctly by running a "Hello world"
# container, then removing it.
#-------------------------------------------------------------------------------
verifyDockerInstall() {
  echoComment "Verifying $SERVICE install."
  echoSeparator
  docker run hello-world
  echoSeparator
  echoComment "If $SERVICE was installed correctly, Hello World will appear above."
  
  echoComment "Removing verification data and container."
  echoSeparator
  docker system prune -af
  echoSeparator
  echoComment "Verification data and container removed."
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

    removeExistingDocker
    
    installDockerDependencies

    installDockerGpgKey
    installDockerRepository

    installDocker

    verifyDockerInstall
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"