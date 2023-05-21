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
# Changes are stored in a conf file in /etc/ssh/sshd_config.d/99-hardened.conf.
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
GLOBAL_SSH_DIR=/etc/ssh
SSHD_CONF=$GLOBAL_SSH_DIR/sshd_config
SSHD_CONF=./sshd_config
SSHD_CONF_DIR=$GLOBAL_SSH_DIR/sshd_config.d
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
# Removes the config files within $SSHD_CONF_DIR, based on the users input.
#
# If the user requests to delete, the files are deleted and the folder is listed
# again to confirm deletion, using `listCurrentSshdConfigs`.
#
# If the user doesn't request to delete, the files are left alone.
#
# Any input other than `y`, `Y`, `n` or `N` will re-run this function.
#-------------------------------------------------------------------------------
removeCurrentSShdConfigs () {
  echo "$COMMENT_PREFIX"'Do you want to remove the configs in '"$SSHD_CONF_DIR"' (y/n)?' 
  read -p "$COMMENT_PREFIX"'N.B. This cannot be undone, and we wont ask for confirmation.' SSHD_CONFS_YN

  if [ $SSHD_CONFS_YN = 'y' -o $SSHD_CONFS_YN = 'Y' ]; then
    echo "$COMMENT_PREFIX"'Deleting files in '"$SSHD_CONF_DIR"'.'
    rm $SSHD_CONF_DIR/*
    echo "$COMMENT_PREFIX"'Files deleted.'

    listCurrentSshdConfigs
  elif [ $SSHD_CONFS_YN = 'n' -o $SSHD_CONFS_YN = 'N' ]; then
    echo "$COMMENT_PREFIX"'Leaving files in '"$SSHD_CONF_DIR"' intact.'
  else
    echo "$COMMENT_PREFIX"'You must answer y or n.'
    removeCurrentSShdConfigs
  fi
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

#-------------------------------------------------------------------------------
# 
#-------------------------------------------------------------------------------
createHardenedSShdConfig () {
  # Do we ask for a port number or generate it?
  # How do we store port number for future use?
  echo "$COMMENT_PREFIX"'Generating sshd config file at '"$SSHD_DEFAULT_CONF"'.' 
  cat <<EOF > $SSHD_DEFAULT_CONF
Port $SSH_PORT
AddressFamily inet
LoginGraceTime 20
PermitRootLogin no
MaxAuthTries 3
MaxSessions 3
AuthenticationMethods publickey
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
KbdInteractiveAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
UsePAM no
AllowAgentForwarding no
X11Forwarding no
PermitUserEnvironment no
#AcceptEnv LANG LC_*
EOF
  echo "$COMMENT_PREFIX"'Config file generated.'
}

#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
# echoLocalSshConfig () {
#   # Do we need this?
# }

listCurrentSshdConfigs
TEST=$(generatePortNumber)
PORT_TEST=$(checkPortNumber 00000 sshPort)
READ_TEST=$(readSetupConfigOption initialisedSetup)
echo "$COMMENT_PREFIX"'Your port number is '"$TEST"'.'
echo "$COMMENT_PREFIX"'The result the port test is '"$PORT_TEST"'.'
echo "$COMMENT_PREFIX"'The result of the read test is '"$READ_TEST"'.'
# removeCurrentSshdConfigs
# checkSshdConfig
# createHardenedSShdConfig
# setPermissions 600 $SSHD_CONF_DIR
# controlService restart sshd
# echoLocalSshConfig