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
. ./linshafun/docker-secrets.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/docker-volumes.sh
# . ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
. ./linshafun/host-information.sh
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
# Config key and service variables.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredDocker'
SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" "lower")"

#-------------------------------------------------------------------------------
# Linux distribution variables.
#-------------------------------------------------------------------------------
HOST_ARCHITECTURE="$(getHostArchitecture)"
OS_DISTRIBUTION="$(getOsDistribution)"
OS_CODENAME="$(getOsCodename)"

#-------------------------------------------------------------------------------
# Installs all components of docker, after updating and upgrading packages to
# ensure use of the added docker repository.
#-------------------------------------------------------------------------------
installDocker () {
  printComment "Installing $SERVICE."
  printSeparator
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
  printComment "Installing dependencies for $SERVICE."
  printSeparator
  updateUpgrade
  installRemovePackages "install" "ca-certificates" "curl" "gnupg"
}

#-------------------------------------------------------------------------------
# Adds the GPG key for docker.
#-------------------------------------------------------------------------------
installDockerGpgKey () {
  printComment "Adding official GPG key for $SERVICE."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/$OS_DISTRIBUTION/gpg" -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  printComment 'GPG key added.'
}

#-------------------------------------------------------------------------------
# Sets up the repository for docker to enable install via "apt install".
#-------------------------------------------------------------------------------
installDockerRepository () {
  printComment "Setting up the repository for $SERVICE."
  echo \
  "deb [arch=$HOST_ARCHITECTURE signed-by=/etc/apt/keyrings/docker.asc] "https://download.docker.com/linux/$OS_DISTRIBUTION" \
  "$OS_CODENAME" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  printComment 'Repository set up.'
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
    printComment "Removing existing installation of $SERVICE."
    installRemovePackages "remove" "docker.io" "docker-doc" "docker-compose" "podman-docker" "containerd" "runc"
    installRemovePackages "remove" "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"

    mainScript
  else
    printComment "Leaving current $SERVICE installation intact."
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
  printComment "Verifying $SERVICE install."
  printSeparator
  $SERVICE run hello-world
  printSeparator
  printComment "If $SERVICE was installed correctly, Hello World will appear above."
  
  printComment "Removing verification data and container."
  printSeparator
  $SERVICE system prune -af
  printSeparator
  printComment "Verification data and container removed."
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  printComment "Starting setup of $SERVICE."

  local SERVICE_TF="$(checkForPackage "$SERVICE")"

  printCheckResult "for $SERVICE" "$SERVICE_TF"

  if [ "$SERVICE_TF" = true ]; then
    printComment "You have already installed $SERVICE."

    removeExistingDocker
  elif [ "$SERVICE_TF" = false ]; then
    printComment "You need to install $SERVICE."
  
    installDockerDependencies

    installDockerGpgKey
    installDockerRepository

    installDocker

    checkForAndCreateDockerSecretsDir

    verifyDockerInstall
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"
