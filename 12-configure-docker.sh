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
. ./linshafun/linshafun-docker.var

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
. ./linshafun/docker-secrets.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/docker-volumes.sh
. ./linshafun/files-directories.sh
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
# ensure use of the added docker repository. Returns 1 with an error if "apt
# update" fails, or if any package can't be installed.
# 
# N.B.
# We are using "apt update" here rather than "updateAndUpgradePackages" to avoid
# unnecessary upgrades of other packages.
#-------------------------------------------------------------------------------
installDocker () {
  printComment "Installing $SERVICE."
  printSeparator

  if ! apt update; then
    printComment --error 'Failed to update the package lists.'

    return 1
  fi

  managePackages "install" "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
}

#-------------------------------------------------------------------------------
# Installs the dependencies necessary to run docker, after updating and 
# upgrading packages. Returns 1 if packages can't be updated or installed.
#
# N.B.
# Some of the dependencies may already be installed.
#-------------------------------------------------------------------------------
installDockerDependencies () {
  printComment "Installing dependencies for $SERVICE."
  printSeparator
  updateAndUpgradePackages || return 1
  managePackages "install" "ca-certificates" "curl" "gnupg"
}

#-------------------------------------------------------------------------------
# Adds the GPG key for docker. Returns 1 with an error if the key can't be
# downloaded or saved.
#-------------------------------------------------------------------------------
installDockerGpgKey () {
  printComment "Adding official GPG key for $SERVICE."

  if ! install -m 0755 -d /etc/apt/keyrings \
    || ! curl -fsSL "https://download.docker.com/linux/$OS_DISTRIBUTION/gpg" -o /etc/apt/keyrings/docker.asc \
    || ! chmod a+r /etc/apt/keyrings/docker.asc; then
    printComment --error "Failed to add the GPG key for $SERVICE."

    return 1
  fi

  printComment 'GPG key added.'
}

#-------------------------------------------------------------------------------
# Sets up the repository for docker to enable install via "apt install".
# Returns 1 with an error if the repository file can't be written.
#-------------------------------------------------------------------------------
installDockerRepository () {
  printComment "Setting up the repository for $SERVICE."

  if ! echo \
  "deb [arch=$HOST_ARCHITECTURE signed-by=/etc/apt/keyrings/docker.asc] "https://download.docker.com/linux/$OS_DISTRIBUTION" \
  "$OS_CODENAME" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
    printComment --error "Failed to set up the repository for $SERVICE."

    return 1
  fi

  printComment 'Repository set up.'
}

#-------------------------------------------------------------------------------
# Removes any existing install of docker, then runs "mainScript" again to
# install it. Returns 1 if the packages can't be removed, or if the new install
# fails.
#
# N.B.
# There are two remove commands, one for older installs, and another for any
# install performed by this script. "checkForPackagesAndRemove" only removes
# packages that are installed, so a package that isn't available on the host
# doesn't stop the removal.
#
# Removing the packages keeps images, containers and volumes in
# "/var/lib/docker".
#-------------------------------------------------------------------------------
removeExistingDocker () {
  promptForUserInput "Do you want to remove the existing install of $SERVICE (y/n)?"
  DOCKER_REMOVE_YN=false
  if getUserInputYN; then DOCKER_REMOVE_YN=true; fi

  if [ "$DOCKER_REMOVE_YN" = true ]; then
    printComment "Removing existing installation of $SERVICE."
    checkForPackagesAndRemove "docker.io" "docker-doc" "docker-compose" "podman-docker" "containerd" "runc" || return 1
    checkForPackagesAndRemove "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin" || return 1

    mainScript
  else
    printComment "Leaving current $SERVICE installation intact."
  fi
}

#-------------------------------------------------------------------------------
# Verifies that the docker install worked correctly by running a "Hello world"
# container, which is removed when it exits, then removing its image. Returns 1
# with an error if the container can't be run.
#
# N.B.
# Only the "hello-world" container and image are removed. Any other images or
# containers, e.g. ones kept from an install that was removed, are left alone.
#-------------------------------------------------------------------------------
verifyDockerInstall() {
  printComment "Verifying $SERVICE install."
  printSeparator

  if ! "$SERVICE" run --rm hello-world; then
    printSeparator
    printComment --error "Failed to run the hello-world container, so $SERVICE may not be installed correctly."

    return 1
  fi

  printSeparator
  printComment "If $SERVICE was installed correctly, Hello World will appear above."
  
  printComment "Removing verification image."
  printSeparator
  "$SERVICE" image rm hello-world
  printSeparator
  printComment "Verification image removed."
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script. Returns 1 as soon as a step fails.
#
# N.B.
# "$DKR_SECRETS_DIR_PATH" is created with mode "700", so only root can read the
# secrets in it.
#-------------------------------------------------------------------------------
mainScript () {
  printComment "Starting setup of $SERVICE."

  printComment "Checking for $SERVICE."
  local SERVICE_TF=false
  if checkForPackage 'docker-ce'; then SERVICE_TF=true; fi

  if [ "$SERVICE_TF" = true ]; then
    printComment "You have already installed $SERVICE."

    removeExistingDocker
  elif [ "$SERVICE_TF" = false ]; then
    printComment "You need to install $SERVICE."
  
    installDockerDependencies || return 1

    installDockerGpgKey || return 1
    installDockerRepository || return 1

    installDocker || return 1

    createDirectory "$DKR_SECRETS_DIR_PATH" '700' || return 1

    verifyDockerInstall
  fi
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
