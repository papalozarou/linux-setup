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
. ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
. ./linshafun/host-information.sh
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
SSH_SOCKET_CONF_DIR="/etc/systemd/system/ssh.socket.d"
SSH_SOCKET_OVERRIDE_CONF="$SSH_SOCKET_CONF_DIR/override.conf"

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
    rm "$SSHD_CONF_DIR"/*.conf
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
    grep "Include" "$SSHD_CONF"
    echoSeparator
  else
    echoComment "Include line already present."
  fi
}

#-------------------------------------------------------------------------------
# Configures the SSH socket on Ubuntu versions above 22.xx. A check is performed
# to see if the override config file exists. If not it is created.
# 
# This is necessary to override the port value in the other config files. 
# As per:
# 
# https://serverfault.com/a/1159600
#-------------------------------------------------------------------------------
configureSshSocket () {
  local SOCKET_CONF_TF="$(checkForFileOrDirectory "$SSH_SOCKET_OVERRIDE_CONF")"
  local SOCKET_CONF_DIR_TF="$(checkForFileOrDirectory "$SSH_SOCKET_CONF_DIR")"

  echoComment 'Checking for the socket config file or directory at:'
  # echoComment "$SSH_SOCKET_CONF_DIR"
  echoComment "$SSH_SOCKET_OVERRIDE_CONF"

  echoComment "Check for config file returned $SOCKET_CONF_TF."
  echoComment "Check for config directory returned $SOCKET_CONF_DIR_TF."

  if [ "$SOCKET_CONF_TF" = true ]; then 
    echoComment 'The setup config file and directory exist.'
    echoComment 'You will need to manually add the following to:'
    echoComment "$SSH_SOCKET_OVERRIDE_CONF"
    echoSeparator
    echoComment '[Socket]'
    echoComment 'ListenStream='
    echoComment "ListenStream=$SSH_PORT"
    echoSeparator
  else
    echoComment 'The setup config file and directory do not exist. Creating both.'

    createDirectory "$SSH_SOCKET_CONF_DIR"
    createSocketOverideConfig
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
# Creates an override config file for the ssh socket on Ubuntu versions above 
# 22.xx. This is necessary to overide the port value in the config files. 
# As per:
# 
# https://serverfault.com/a/1159600
#-------------------------------------------------------------------------------
createSocketOverideConfig () {
  echoComment 'Generating ssh.socket override config file at:' 
  echoComment "$SSH_SOCKET_CONF_DIR" 
  cat <<EOF > "$SSH_SOCKET_OVERRIDE_CONF"
[Socket]
ListenStream=
ListenStream=$SSH_PORT
EOF
  echoComment 'Override config file generated.'

  listDirectories "$SSH_SOCKET_CONF_DIR"
}

#-------------------------------------------------------------------------------
# Asks they user if they want to restart the sshd service. Applies to versions
# of Ubuntu lower than or equal to 22.04.
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
# Asks they user if they want to restart the ssh socket. Applies to versions of
# Ubuntu greater than 22.04.
#-------------------------------------------------------------------------------
restartSshSocket () {
  echoComment 'To enable the new ssh socker configutation, you will need to restart'
  echoComment 'the ssh socket. This can potentially interupt your connection.'
  promptForUserInput 'Do you want to restart the ssh socket (y/n)?'
  SSH_SOCKET_RESTART_YN="$(getUserInput)"

  if [ "$SSH_SOCKET_RESTART_YN" = 'y' -o "$SSH_SOCKET_RESTART_YN" = 'Y' ]; then
    systemctl daemon-reload
    controlService 'restart' 'ssh.socket'
  elif [ "$SSH_SOCKET_RESTART_YN" = 'n' -o "$SSH_SOCKET_RESTART_YN" = 'N' ]; then
    echoComment 'The ssh socket will not be restarted.'
  else
    echoComment 'You must answer y or n.'
    restartSshd
  fi
}

#-------------------------------------------------------------------------------
# Displays the values a user needs to add to their local ssh config file.
#-------------------------------------------------------------------------------
echoLocalSshConfig () {
  local IP_ADDRESS="$(readIpAddress)"
  local SSH_KEY_FILE="$(readSetupConfigValue "sshKeyFile")"

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
# Executes the main functions of the script. A check is performed on the version
# of Ubuntu that the host is running – if higher than 22.xx then the SSH socket
# is also configured. As per:
#
# https://serverfault.com/a/1159600
#
# N.B.
# SSHD is only restarted if Ubuntu 22 or lower is running. As per:
#
# https://askubuntu.com/a/1523872
# https://askubuntu.com/a/1439482
#-------------------------------------------------------------------------------
mainScript () {
  local UBUNTU_22_TF="$(compareOsVersion "22.04")"

  listDirectories "$SSHD_CONF_DIR"
  removeCurrentSshdConfigs

  checkSshdConfig
  createHardenedSShdConfig
  setPermissions "600" "$SSHD_CONF_DIR"

  echoComment "The check to see if your OS is greater than Ubuntu 22.04 returned $UBUNTU_22_TF."

  if [ "$UBUNTU_22_TF" = false ]; then
    echoComment 'You are on a version of Ubuntu that is higher than 22.04.'
    echoComment 'We must also configure the SSH socket.'
    configureSshSocket

    restartSshSocket
  else
    restartSshd
  fi

  writeSetupConfigOption "sshPort" "$SSH_PORT"
  
  echoLocalSshConfig
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"