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
# . ./linshafun/docker-secrets.sh
# . ./linshafun/docker-services.sh
# . ./linshafun/docker-volumes.sh
. ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
. ./linshafun/host-information.sh
# . ./linshafun/host-initialisation.sh
# . ./linshafun/initialisation.sh
. ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
. ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
. ./linshafun/ssh-config.sh
# . ./linshafun/ssh-keys.sh
# . ./linshafun/text.sh
. ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredSshd'

#-------------------------------------------------------------------------------
# Directory variables.
#-------------------------------------------------------------------------------
GLOBAL_SSH_DIR_PATH='/etc/ssh'
SSHD_CONF_DIR_PATH="$GLOBAL_SSH_DIR_PATH/sshd_config.d"
SSH_SOCKET_CONF_DIR_PATH="/etc/systemd/system/ssh.socket.d"

#-------------------------------------------------------------------------------
# File variables.
#-------------------------------------------------------------------------------
SSHD_CONF_PATH="$GLOBAL_SSH_DIR_PATH/sshd_config"
SSHD_DEFAULT_CONF_PATH="$SSHD_CONF_DIR_PATH/99-hardened.conf"
SSH_SOCKET_OVERRIDE_CONF_PATH="$SSH_SOCKET_CONF_DIR_PATH/override.conf"

#-------------------------------------------------------------------------------
# SSH variables.
#-------------------------------------------------------------------------------
SSH_PORT="$(generatePortNumber)"

#-------------------------------------------------------------------------------
# Check for the "Include" line in "$SSHD_CONF". If not present, add it after
# the first comment block at the top of the config file. If it is present,
# confirm it's present.
#
# N.B.
# The "sed" command is in double quotes to ensure variable substitution of
# "$SSHD_CONF_DIR" as per:
#
# - https://stackoverflow.com/a/748586
#
# For the newline to work the "\" and the "n" must be escaped, hence the triple
# "\\\" in the command.
#-------------------------------------------------------------------------------
checkSshdConfig () {
  if grep -q "Include" "$SSHD_CONF_PATH"; then
    local INCLUDES_TF=true
  else
    local INCLUDES_TF=false
  fi

  printCheckResult "for include line in the sshd config file" "$INCLUDES_TF"

  if [ "$INCLUDES_TF" = true ]; then
    printComment "Include line already present."
  elif [ "$INCLUDES_TF" = false ]; then
    printComment 'Include line not present so adding it.' 'warning'

    sed -i "/value\./a \\\nInclude $SSHD_CONF_DIR_PATH/*.conf" "$SSHD_CONF_PATH"
    printComment "Added include line."
    printSeparator
    grep "Include" "$SSHD_CONF_PATH"
    printSeparator
  fi
}

#-------------------------------------------------------------------------------
# Configures the SSH socket on Ubuntu versions above 22.xx. A check is performed
# to see if the override config file exists. If not it is created.
# 
# This is necessary to override the port value in the other config files. 
# As per:
# 
# - https://serverfault.com/a/1159600
#-------------------------------------------------------------------------------
configureSshSocket () {
  local SOCKET_CONF_TF="$(checkForFileOrDirectory "$SSH_SOCKET_OVERRIDE_CONF_PATH")"
  local SOCKET_CONF_DIR_TF="$(checkForFileOrDirectory "$SSH_SOCKET_CONF_DIR_PATH")"

  printCheckResult 'for the socket config file' "$SOCKET_CONF_TF"
  printCheckResult 'for the socket config directory' "$SOCKET_CONF_DIR_TF"

  if [ "$SOCKET_CONF_TF" = true ]; then 
    printComment 'The setup config file and directory exist. You will need to manually add the following to:' 'warning'
    printComment "$SSH_SOCKET_OVERRIDE_CONF_PATH" 'warning'
    printSeparator
    printComment '[Socket]'
    printComment 'ListenStream='
    printComment "ListenStream=$SSH_PORT"
    printSeparator
  else
    printComment 'The setup config file and directory do not exist. Creating both.' 'warning'

    createDirectory "$SSH_SOCKET_CONF_DIR_PATH"
    createSocketOverideConfig
  fi
}

#-------------------------------------------------------------------------------
# Creates the hardened config file for sshd. This overides the default values
# stored in "$SSHD_CONF_PATH".
#-------------------------------------------------------------------------------
createHardenedSShdConfig () {
  printComment 'Generating sshd config file at:' 
  printComment "$SSHD_DEFAULT_CONF_PATH" 
  cat <<EOF > "$SSHD_DEFAULT_CONF_PATH"
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
  printComment 'Config file generated.'

  listDirectories "$SSHD_CONF_DIR_PATH"
}

#-------------------------------------------------------------------------------
# Creates an override config file for the ssh socket on Ubuntu versions above 
# 22.xx. This is necessary to overide the port value in the config files. 
# As per:
# 
# - https://serverfault.com/a/1159600
#-------------------------------------------------------------------------------
createSocketOverideConfig () {
  printComment 'Generating ssh.socket override config file at:' 
  printComment "$SSH_SOCKET_CONF_DIR_PATH" 
  cat <<EOF > "$SSH_SOCKET_OVERRIDE_CONF_PATH"
[Socket]
ListenStream=
ListenStream=$SSH_PORT
EOF
  printComment 'Override config file generated.'

  listDirectories "$SSH_SOCKET_CONF_DIR_PATH"
}

#-------------------------------------------------------------------------------
# Removes the config files within "$SSHD_CONF_DIR_PATH", based on the users 
# input.
#
# If the user requests to delete, the files are deleted and the folder is listed
# again to confirm deletion, using "listDirectories".
#
# If the user doesn't request to delete, the files are left alone.
#
# N.B.
# We must run "rm" from a shell, as shell does the expansion of the wildcard,
# "*", not "rm". As per:
# 
# - https://stackoverflow.com/a/31559110
#-------------------------------------------------------------------------------
removeCurrentSshdConfigs () {
  promptForUserInput "Do you want to remove the configs in $SSHD_CONF_DIR_PATH (y/n)?" 'This cannot be undone, and we wont ask for confirmation.'
  SSHD_CONFS_YN="$(getUserInputYN)"

  if [ "$SSHD_CONFS_YN" = true ]; then
    printComment "Deleting files in $SSHD_CONF_DIR_PATH."
    rm "$SSHD_CONF_DIR_PATH"/*.conf
    printComment 'Files deleted.'

    listDirectories "$SSHD_CONF_DIR_PATH"
  else
    printComment "Leaving files in $SSHD_CONF_DIR_PATH intact."
  fi
}

#-------------------------------------------------------------------------------
# Asks the user if they want to restart the sshd service. Applies to versions
# of Debian and Ubuntu versions lower than or equal to 22.04.
#-------------------------------------------------------------------------------
restartSshd () {
  printComment 'To enable the new sshd configutation, you will need to restart sshd.' 'warning'
  promptForUserInput 'Do you want to restart sshd (y/n)?' 'This can potentially interupt your connection.'
  SSHD_RESTART_YN="$(getUserInputYN)"

  if [ "$SSHD_RESTART_YN" = true ]; then
    controlService 'restart' 'sshd'
  else
    printComment 'sshd will not be restarted.'
  fi
}

#-------------------------------------------------------------------------------
# Asks the user if they want to restart the ssh socket. Applies to versions of
# Ubuntu greater than 22.04.
#-------------------------------------------------------------------------------
restartSshSocket () {
  printComment 'To enable the new ssh socket configutation, you will need to restart the ssh socket.' 'warning'
  promptForUserInput 'Do you want to restart the ssh socket (y/n)?' 'This can potentially interupt your connection.'
  SSH_SOCKET_RESTART_YN="$(getUserInputYN)"

  if [ "$SSH_SOCKET_RESTART_YN" = true ]; then
    systemctl daemon-reload
    controlService 'restart' 'ssh.socket'
  else
    printComment 'The ssh socket will not be restarted.'
  fi
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script. A check is performed on the Linux
# distribution the host machine is running. If it is Ubuntu and higher than 
# 22.xx then the SSH socket is also configured. As per:
#
# - https://serverfault.com/a/1159600
#
# N.B.
# SSHD is only restarted if the distribution is Debian or Ubunto 22 or lower. 
# As per:
#
# - https://askubuntu.com/a/1523872
# - https://askubuntu.com/a/1439482
#-------------------------------------------------------------------------------
mainScript () {
  local OS_DISTRIBUTION="$(getOsDistribution)"

  if [ "$OS_DISTRIBUTION" = "ubuntu" ]; then
    local UBUNTU_22_TF="$(compareOsVersion "22.04")"
  fi

  listDirectories "$SSHD_CONF_DIR_PATH"
  removeCurrentSshdConfigs

  checkSshdConfig
  createHardenedSShdConfig
  setPermissions "600" "$SSHD_CONF_DIR_PATH"

  if [ "$UBUNTU_22_TF" = false ]; then
    printComment 'You are on a version of Ubuntu that is higher than 22.04. We must also configure the SSH socket.'
    configureSshSocket

    restartSshSocket
  fi

  restartSshd

  writeSetupConfigOption "sshPort" "$SSH_PORT"
  
  printLocalSshConfig "$SSH_PORT"
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"