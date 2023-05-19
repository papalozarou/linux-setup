#!/bin/sh

#-------------------------------------------------------------------------------
# Install and configure fail2ban. The configuration is stored at
# /etc/fail2ban/jail.local
#
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh