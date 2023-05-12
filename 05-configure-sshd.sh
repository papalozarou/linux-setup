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

#-------------------------------------------------------------------------------
# SSHD related variables.
#-------------------------------------------------------------------------------
SSH_DIR=/etc/ssh
SSHD_CONF=$SSH_DIR/sshd_config
SSHD_CONF=./sshd_config
SSHD_CONF_DIR=$SSH_DIR/sshd_config.d
SSHD_DEFAULT_CONF=$SSHD_CONF_DIR/99-defaults.conf

#-------------------------------------------------------------------------------
# Lists the current contents of `$SSD_CONF_DIR` as a percursor to allowing the
# user to delete them if required, e.g. if a Cloud provider or distro has auto 
# installed files here.
#-------------------------------------------------------------------------------
listCurrentSshdConfigs() {
  echo "$COMMENT_PREFIX"'Listing '"$SSHD_CONF_DIR"'…'
  echo "$COMMENT_SEPARATOR"
  ls -lna $SSHD_CONF_DIR
  echo "$COMMENT_SEPARATOR"
}

#-------------------------------------------------------------------------------
# Removes the config files within $SSHD_CONF_DIR, if the user requests it.
#-------------------------------------------------------------------------------
removeCurrentSShdConfigs () {
  echo "$COMMENT_PREFIX"
}

#-------------------------------------------------------------------------------
# Check for the `Include` line in `$SSHD_CONF`. If not present, add it after
# the first comment block at the top of the config file. If it is present,
# confirm it's present.
#
# N.B.
# The `sed` command is in double quotes to ensure variable substitution of
# `$SSHD_CONF_DIR` as per:
#
# https://stackoverflow.com/questions/584894/environment-variable-substitution-in-sed#748586
#
# For the newline to work the `\` and the `n` must be escaped, hence the triple
# `\\\` in the command.
#-------------------------------------------------------------------------------
checkSshdConfig () {
  echo "$COMMENT_PREFIX"'Checking for include line in '"$SSHD_CONF"'.'

  local INCLUDES=$(cat $SSHD_CONF | grep "Include")

  if [ -z "$INCLUDES" ]; then
    echo "$COMMENT_PREFIX"'Include line not present so adding to '"$SSHD_CONF"'.'

    sed -i "/value\./a \\\nInclude $SSHD_CONF_DIR/*.conf" $SSHD_CONF
    echo "$COMMENT_PREFIX"'Added include line to '"$SSHD_CONF"'.'
    echo "$COMMENT_SEPARATOR"
    echo $(cat ./sshd_config | grep "Include")
    echo "$COMMENT_SEPARATOR"
  else
    echo "$COMMENT_PREFIX"'Include line already present in '"$SSHD_CONF"'.'
  fi
}

listCurrentSshdConfigs
checkSshdConfig