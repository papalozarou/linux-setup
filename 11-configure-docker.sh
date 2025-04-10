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
# Imported shared variables.
#-------------------------------------------------------------------------------
. ./linshafun/linshafun.var

#-------------------------------------------------------------------------------
# Imported project specific variables.
#-------------------------------------------------------------------------------
. ./linux-setup.var

#-------------------------------------------------------------------------------
# Imported shared functions.
#-------------------------------------------------------------------------------
. ./linshafun/comments.sh
# . ./linshafun/docker-env-variables.sh
# . ./linshafun/docker-images.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/docker-volumes.sh
# . ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
# . ./linshafun/host-information.sh
# . ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
. ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-keys.sh
. ./linshafun/text.sh
. ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredDocker'
SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" "lower")"

#-------------------------------------------------------------------------------
# Linux distribution variables.
#
# N.B.
# The "-d" flag is not required with "cut" in this instance as the returned 
# string is split by tabs. As per:
#
# - https://unix.stackexchange.com/a/35387
#-------------------------------------------------------------------------------
DISTRIBUTION_ID="$(lsb_release -a | grep "Distributor" | cut -f 2)"
DISTRIBUTION="$(changeCase "$DISTRIBUTION_ID" 'lower')"

#-------------------------------------------------------------------------------
# Installs all components of docker, after updating and upgrading packages to
# ensure use of the added docker repository.
#-------------------------------------------------------------------------------
installDocker () {
  echoComment "Installing $SERVICE."
  echoSeparator
  updateUpgrade
  installRemovePackages "install" "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
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
  installRemovePackages "install" "ca-certificates" "curl" "gnupg"
}

#-------------------------------------------------------------------------------
# Adds the GPG key for docker.
#-------------------------------------------------------------------------------
installDockerGpgKey () {
  echoComment "Adding official GPG key for $SERVICE."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/$DISTRIBUTION/gpg" -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echoComment 'GPG key added.'
}

#-------------------------------------------------------------------------------
# Sets up the repository for docker to enable install via "apt install".
#-------------------------------------------------------------------------------
installDockerRepository () {
  echoComment "Setting up the repository for $SERVICE."
  echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.asc] "https://download.docker.com/linux/$DISTRIBUTION" \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  echoComment 'Repository set up.'
}

#-------------------------------------------------------------------------------
# Removes any existing install of docker.
#
# N.B.
# There are two remove commands, one for older installs, and another for any
# install performed by this script.
#-------------------------------------------------------------------------------
removeExistingDocker () {
  promptForUserInput "Do you want to remove the existing install of $SERVICE (y/n)?"
  DOCKER_REMOVE_YN="$(getUserInputYN)"

  if [ "$DOCKER_REMOVE_YN" = true ]; then
    echoComment "Removing existing installation of $SERVICE."
    installRemovePackages "remove" "docker.io" "docker-doc" "docker-compose" "podman-docker" "containerd" "runc"
    installRemovePackages "remove" "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"

    mainScript
  else
    echoComment "Leaving current $SERVICE installation intact."
  fi
}

#-------------------------------------------------------------------------------
# Verifies that the docker install worked correctly by running a "Hello world"
# container, then removing it.
#
# N.B.
# Had to add a shell command to get docker to run from this function.
#-------------------------------------------------------------------------------
verifyDockerInstall() {
  echoComment "Verifying $SERVICE install."
  echoSeparator
  $SERVICE run hello-world
  echoSeparator
  echoComment "If $SERVICE was installed correctly, Hello World will appear above."
  
  echoComment "Removing verification data and container."
  echoSeparator
  $SERVICE system prune -af
  echoSeparator
  echoComment "Verification data and container removed."
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  echoComment "Starting setup of $SERVICE."

  local SERVICE_CHECK="$(checkForPackage "$SERVICE")"
  echoComment "Checking for $SERVICE."
  echoComment "Check returned $SERVICE_CHECK."

  if [ "$SERVICE_CHECK" = true ]; then
    echoComment "You have already installed $SERVICE."

    removeExistingDocker
  elif [ "$SERVICE_CHECK" = false ]; then
    echoComment "You need to install $SERVICE."
  
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
