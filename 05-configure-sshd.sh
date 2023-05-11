#!/bin/sh

#-------------------------------------------------------------------------------
# Configures sshd to harden access by:
#
# 1. changing the default port;
# 2. not allowing root login;
# 2. only allowing authentication with public keys;
# 3. disallowing X11 and agent forwarding; and
# 4. not permitting user environment variables to be passed.
#
# Changes are stored in a conf file in /etc/ssh/sshd_config.d/99-defaults.conf.
# Once changes have been made, the ssh daemon is restarted.
#
# This script is based on:
#
# https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-on-ubuntu-20-04
#
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

SSH_DIR=/etc/ssh
SSHD_CONF=$SSH_DIR/sshd_config
SSHD_CONF_DIR=$SSH_DIR/sshd_config.d
SSHD_DEFAULT_CONF=$SSHD_CONF_DIR/99-defaults.conf

#-------------------------------------------------------------------------------
# 
#-------------------------------------------------------------------------------
checkCurrentSshdConfigs() {
  echo "$COMMENT_PREFIX"'Listing '"$SSHD_CONF_DIR"'…'
  echo "$COMMENT_SEPARATOR"
  ls -lna $SSHD_CONF_DIR
  echo "$COMMENT_SEPARATOR"
}

#-------------------------------------------------------------------------------
# 
#-------------------------------------------------------------------------------
removeCurrentSShdConfigs () {
  echo "$COMMENT_PREFIX"
}

#-------------------------------------------------------------------------------
# 
#-------------------------------------------------------------------------------
checkSshdConfig () {
  echo "$COMMENT_PREFIX"'Checking for include line in '"$SSHD_CONF"'.'

  local INCLUDES=$(cat ./sshd_config | grep "Include")

  if [ -z "$INCLUDES" ]; then
    echo "$COMMENT_PREFIX"'Include line not present so adding to '"$SSHD_CONF"'.'

    sed -i '/value\./a \\nInclude /etc/ssh/sshd_config.d/*.conf' ./sshd_config
    echo "$COMMENT_PREFIX"'Added include line to '"$SSHD_CONF"'.'
    echo "$COMMENT_SEPARATOR"
    echo $(cat ./sshd_config | grep "Include")
    echo "$COMMENT_SEPARATOR"

  else
    echo "$COMMENT_PREFIX"'Include line already present in '"$SSHD_CONF"'.'
  fi
}

checkCurrentSshdConfigs
checkSshdConfig