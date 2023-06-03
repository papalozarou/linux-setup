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

  
}

#-------------------------------------------------------------------------------
# Performas the initial check to see if this step has already been completed.
#-------------------------------------------------------------------------------
initialiseScript configureUfw