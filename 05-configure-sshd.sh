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
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported variables.
#-------------------------------------------------------------------------------
. ./linshafun/setup.var

#-------------------------------------------------------------------------------
# Imported shared functions.
#-------------------------------------------------------------------------------
. ./linshafun/comments.sh
# . ./linshafun/docker-env-variables.sh
# . ./linshafun/docker-images.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
. ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
. ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-keys.sh
# . ./linshafun/text.sh
. ./linshafun/user-input.sh
#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredSshd'

#-------------------------------------------------------------------------------
# sshd related variables.
#-------------------------------------------------------------------------------
GLOBAL_SSH_DIR='/etc/ssh'
SSHD_CONF="$GLOBAL_SSH_DIR/sshd_config"
SSHD_CONF_DIR="$GLOBAL_SSH_DIR/sshd_config.d"
SSHD_DEFAULT_CONF="$SSHD_CONF_DIR/99-hardened.conf"

#-------------------------------------------------------------------------------
# Removes the config files within "$SSHD_CONF_DIR", based on the users input.
#
# If the user requests to delete, the files are deleted and the folder is listed
# again to confirm deletion, using "listDirectories".
#
# If the user doesn't request to delete, the files are left alone.
#
# Any input other than "y", "Y", "n" or "N" will re-run this function.
#
# N.B.
# We must run "rm" from a shell, as shell does the expansion of the wildcard,
# "*", not "rm". As per:
# 
# https://stackoverflow.com/a/31559110
#-------------------------------------------------------------------------------
removeCurrentSshdConfigs () {
  promptForUserInput "Do you want to remove the configs in $SSHD_CONF_DIR (y/n)?" 'This cannot be undone, and we wont ask for confirmation.'
  SSHD_CONFS_YN="$(getUserInput)"

  if [ "$SSHD_CONFS_YN" = 'y' -o "$SSHD_CONFS_YN" = 'Y' ]; then
    echoComment "Deleting files in $SSHD_CONF_DIR."
    sh -c "rm $SSHD_CONF_DIR/*.conf"
    echoComment 'Files deleted.'

    listDirectories "$SSHD_CONF_DIR"
  elif [ "$SSHD_CONFS_YN" = 'n' -o "$SSHD_CONFS_YN" = 'N' ]; then
    echoComment "Leaving files in $SSHD_CONF_DIR intact."
  else
    echoComment 'You must answer y or n.'
    removeCurrentSShdConfigs
  fi
}

#-------------------------------------------------------------------------------
# Check for the "Include" line in "$SSHD_CONF". If not present, add it after
# the first comment block at the top of the config file. If it is present,
# confirm it's present.
#
# N.B.
# The "sed" command is in double quotes to ensure variable substitution of
# "$SSHD_CONF_DIR" as per:
#
# https://stackoverflow.com/questions/584894/environment-variable-substitution-in-sed#748586
#
# For the newline to work the "\" and the "n" must be escaped, hence the triple
# "\\\" in the command.
#-------------------------------------------------------------------------------
checkSshdConfig () {
  echoComment 'Checking for include line in:'
  echoComment "$SSHD_CONF"

  local INCLUDES="$(grep "Include" "$SSHD_CONF")"

  if [ -z "$INCLUDES" ]; then
    echoComment 'Include line not present so adding it.'

    sed -i "/value\./a \\\nInclude $SSHD_CONF_DIR/*.conf" "$SSHD_CONF"
    echoComment "Added include line."
    echoSeparator
    sh -c "grep "Include" "$SSHD_CONF""
    echoSeparator
  else
    echoComment "Include line already present."
  fi
}

#-------------------------------------------------------------------------------
# Creates the hardened config file for sshd. This overides the default values
# stored in "$SSHD_CONF".
#-------------------------------------------------------------------------------
createHardenedSShdConfig () {
  SSH_PORT="$(generatePortNumber)"

  echoComment 'Generating sshd config file at:' 
  echoComment "$SSHD_DEFAULT_CONF" 
  cat <<EOF > "$SSHD_DEFAULT_CONF"
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
UsePAM yes
AllowAgentForwarding no
X11Forwarding no
PermitUserEnvironment no
AcceptEnv LANG LC_*
EOF
  echoComment 'Config file generated.'

  listDirectories "$SSHD_CONF_DIR"
}

#-------------------------------------------------------------------------------
# Asks they user if they want to restart the sshd service.
#-------------------------------------------------------------------------------
restartSshd () {
  echoComment 'To enable the new sshd configutation, you will need to restart'
  echoComment 'sshd. This can potentially interupt your connection.'
  promptForUserInput 'Do you want to restart sshd (y/n)?'
  SSHD_RESTART_YN="$(getUserInput)"

  if [ "$SSHD_RESTART_YN" = 'y' -o "$SSHD_RESTART_YN" = 'Y' ]; then
    controlService 'restart' 'sshd'
  elif [ "$SSHD_RESTART_YN" = 'n' -o "$SSHD_RESTART_YN" = 'N' ]; then
    echoComment 'sshd will not be restarted.'
  else
    echoComment 'You must answer y or n.'
    restartSshd
  fi
}

#-------------------------------------------------------------------------------
# Displays the values a user needs to add to their local ssh config file.
#-------------------------------------------------------------------------------
echoLocalSshConfig () {
  local IP_ADDRESS="$(readIPAddress)"
  local SSH_KEY_FILE="$(readSetupConfigOption "sshKeyFile")"

  echoComment 'To enable easy connection from your local machine, add the'
  echoComment 'following to your local ssh config file at either:'
  echoComment '~/.ssh/ssh_config'
  echoComment '~/.ssh/config'
  echoSeparator
  echoComment "Host $SSH_KEY_FILE"
  echoComment "  Hostname $IP_ADDRESS"
  echoComment "  Port $SSH_PORT"
  echoComment "  User $SUDO_USER"
  echoComment "  IdentityFile ~/.ssh/$SSH_KEY_FILE"
  echoSeparator
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  listDirectories "$SSHD_CONF_DIR"
  removeCurrentSshdConfigs

  checkSshdConfig
  createHardenedSShdConfig
  setPermissions "600" "$SSHD_CONF_DIR"

  restartSshd

  writeSetupConfigOption "sshPort" "$SSH_PORT"
  
  echoLocalSshConfig
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"