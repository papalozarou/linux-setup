#!/bin/sh

#-------------------------------------------------------------------------------
# Install and configure ufw to only accept traffic on required ports for ssh.
#
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Runs if this step hasn't been completed before.
#-------------------------------------------------------------------------------
runScript () {
  echo "$COMMENT_PREFIX"'Starting setup of ufw.'

  local UFW_CHECK=$(checkForService ufw)

  if [ $UFW_CHECK = true ]; then
    echo "$COMMENT_PREFIX"'You have already installed ufw.'
  elif [ $UFW_CHECK = false]; then
    echo "$COMMENT_PREFIX"'You need to install ufw.'
    installService ufw
  fi

  echo "$COMMENT_PREFIX"'Explicitly denying incoming traffic.'
  ufw default deny incoming

  echo "$COMMENT_PREFIX"'Explicitly allowing outgoing traffic.'
  ufw default allow outgoing

  echo "$COMMENT_PREFIX"'Explicitly denying port 22.'
  addPortToUFW deny 22
  
  echo "$COMMENT_PREFIX"'Reading ssh port.'
  local SSH_PORT=$(readSetupConfigOption sshPort)
  echo "$COMMENT_PREFIX"'Current port is '"$SSH_PORT"'.'

  addPortToUFW allow $SSH_PORT tcp

  controlService enable ufw

  ufw status numbered

  writeSetupConfigOption configureUfw true

  echoScriptFinished "setting up ufw"
}

#-------------------------------------------------------------------------------
# Performas the initial check to see if this step has already been completed.
#-------------------------------------------------------------------------------
initialiseScript configureUfw