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
# Once changes have been made, the config is checked with "sshd -t", and ssh is
# restarted if the user agrees.
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
. ./linshafun/comments-logs.sh
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
. ./linshafun/text.sh
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
# Check for the "Include" line in "$SSHD_CONF_PATH". If not present, add it
# after the first comment block at the top of the config file. If it is
# present, confirm it's present.
#
# Returns 1 with an error if the line can't be added, including when "sed"
# finds no line containing "value." to add it after.
#
# N.B.
# The "sed" command is in double quotes to ensure variable substitution of
# "$SSHD_CONF_DIR_PATH" as per:
#
# - https://stackoverflow.com/a/748586
#
# For the newline to work the "\" and the "n" must be escaped, hence the triple
# "\\\" in the command.
#-------------------------------------------------------------------------------
checkSshdConfig () {
  local INCLUDE_LINE="Include $SSHD_CONF_DIR_PATH/*.conf"

  printComment 'Checking for the include line in the sshd config file.'

  if grep -q "Include" "$SSHD_CONF_PATH"; then
    printComment "Include line already present."

    return 0
  fi

  printComment --warning 'Include line not present so adding it.'

  if ! sed -i "/value\./a \\\n$INCLUDE_LINE" "$SSHD_CONF_PATH" || ! grep -Fqx "$INCLUDE_LINE" "$SSHD_CONF_PATH"; then
    printComment --error 'Failed to add the include line to:'
    printComment --error -- "$SSHD_CONF_PATH"

    return 1
  fi

  printComment "Added include line."
  printSeparator
  grep "Include" "$SSHD_CONF_PATH"
  printSeparator
}

#-------------------------------------------------------------------------------
# Checks the sshd config, including the files in "$SSHD_CONF_DIR_PATH", with
# "sshd -t". Returns 1 with an error if the config isn't valid, so ssh isn't
# restarted with it.
#
# N.B.
# "sshd -t" prints the problems it finds. The ssh service also runs it before
# starting, so restarting with an invalid config would stop sshd and leave it
# stopped.
#-------------------------------------------------------------------------------
checkSshdConfigSyntax () {
  printComment 'Checking the sshd config with "sshd -t".'

  if ! sshd -t; then
    printComment --error 'The sshd config is not valid, so ssh will not be restarted. Fix the problems listed above, then run this script again.'

    return 1
  fi

  printComment 'The sshd config is valid.'
}

#-------------------------------------------------------------------------------
# Configures the SSH socket on Ubuntu versions above 22.04. A check is performed
# to see if the override config file exists. If not it is created.
# 
# This is necessary to override the port value in the other config files. 
# As per:
# 
# - https://serverfault.com/a/1159600
#
# Returns 1 if the directory or file can't be created.
#
# N.B.
# If the override file already exists, it isn't changed, and the lines to add
# to it are printed instead.
#-------------------------------------------------------------------------------
configureSshSocket () {
  printComment 'Checking for the socket override config file.'

  if checkForFileOrDirectory "$SSH_SOCKET_OVERRIDE_CONF_PATH"; then
    printComment --warning 'The socket override config file already exists. You will need to manually add the following to:'
    printComment --warning -- "$SSH_SOCKET_OVERRIDE_CONF_PATH"
    printSeparator
    printComment '[Socket]'
    printComment 'ListenStream='
    printComment "ListenStream=$SSH_PORT"
    printSeparator

    return 0
  fi

  printComment --warning 'The socket override config file and directory do not exist. Creating both.'

  createDirectory "$SSH_SOCKET_CONF_DIR_PATH" || return 1
  createSocketOverrideConfig
}

#-------------------------------------------------------------------------------
# Creates the hardened config file for sshd. This overrides the default values
# stored in "$SSHD_CONF_PATH". Returns 1 with an error if the file can't be
# written.
#-------------------------------------------------------------------------------
createHardenedSshdConfig () {
  printComment 'Generating sshd config file at:' 
  printComment -- "$SSHD_DEFAULT_CONF_PATH" 

  if ! cat <<EOF > "$SSHD_DEFAULT_CONF_PATH"; then
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
    printComment --error "Failed to write the sshd config file at $SSHD_DEFAULT_CONF_PATH."

    return 1
  fi

  printComment 'Config file generated.'

  listDirectories "$SSHD_CONF_DIR_PATH"
}

#-------------------------------------------------------------------------------
# Creates an override config file for the ssh socket on Ubuntu versions above 
# 22.04. This is necessary to override the port value in the config files. 
# As per:
# 
# - https://serverfault.com/a/1159600
#
# Returns 1 with an error if the file can't be written.
#-------------------------------------------------------------------------------
createSocketOverrideConfig () {
  printComment 'Generating ssh.socket override config file at:' 
  printComment -- "$SSH_SOCKET_OVERRIDE_CONF_PATH" 

  if ! cat <<EOF > "$SSH_SOCKET_OVERRIDE_CONF_PATH"; then
[Socket]
ListenStream=
ListenStream=$SSH_PORT
EOF
    printComment --error "Failed to write the override config file at $SSH_SOCKET_OVERRIDE_CONF_PATH."

    return 1
  fi

  printComment 'Override config file generated.'

  listDirectories "$SSH_SOCKET_CONF_DIR_PATH"
}

#-------------------------------------------------------------------------------
# Removes the config files within "$SSHD_CONF_DIR_PATH", based on the users 
# input. If there are no config files, the user isn't asked.
#
# If the user requests to delete, the files are deleted and the folder is listed
# again to confirm deletion, using "listDirectories".
#
# If the user doesn't request to delete, the files are left alone.
#
# Returns 1 if any file can't be removed. "removeFilesOrDirectories" prints the
# error.
#
# N.B.
# "set --" stores the files matching "*.conf" as this function's arguments. If
# nothing matches, the shell leaves the pattern as written, so the first
# argument isn't a file and there is nothing to remove.
#-------------------------------------------------------------------------------
removeCurrentSshdConfigs () {
  set -- "$SSHD_CONF_DIR_PATH"/*.conf

  if [ ! -f "$1" ]; then
    printComment "There are no config files in $SSHD_CONF_DIR_PATH to remove."

    return 0
  fi

  promptForUserInput "Do you want to remove the configs in $SSHD_CONF_DIR_PATH (y/n)?" "This cannot be undone, and we won't ask for confirmation."

  if ! getUserInputYN; then
    printComment "Leaving files in $SSHD_CONF_DIR_PATH intact."

    return 0
  fi

  printComment "Deleting files in $SSHD_CONF_DIR_PATH."
  removeFilesOrDirectories "$@" || return 1
  printComment 'Files deleted.'

  listDirectories "$SSHD_CONF_DIR_PATH"
}

#-------------------------------------------------------------------------------
# Checks the sshd config, then asks the user if they want to restart ssh to
# apply it. Takes one mandatory argument:
#
# 1. "${1:?}" – "true" if ssh uses socket activation, i.e. Ubuntu above 22.04,
#    otherwise "false".
#
# With socket activation, systemd is reloaded so it reads the socket override,
# and "ssh.socket" is restarted so it listens on the new port. In both cases
# "ssh" is then restarted so sshd reads the new config.
#
# Returns 1 if the config isn't valid, or if a restart fails.
#
# N.B.
# The service is "ssh.service" on Debian and Ubuntu. "sshd.service" is only an
# alias, which systemd creates when "ssh.service" is enabled. With socket
# activation, "ssh.socket" is enabled instead, so the alias may not exist.
#-------------------------------------------------------------------------------
restartSsh () {
  local SOCKET_TF="${1:?}"

  checkSshdConfigSyntax || return 1

  printComment --warning 'To enable the new ssh configuration, you will need to restart ssh.'
  promptForUserInput 'Do you want to restart ssh (y/n)?' 'This can potentially interrupt your connection.'

  if ! getUserInputYN; then
    printComment 'ssh will not be restarted.'

    return 0
  fi

  if [ "$SOCKET_TF" = true ]; then
    restartSshSocket || return 1
  fi

  controlService 'restart' 'ssh'
}

#-------------------------------------------------------------------------------
# Reloads systemd so it reads the socket override, then restarts the ssh
# socket. Applies to versions of Ubuntu greater than 22.04. Returns 1 if either
# fails.
#-------------------------------------------------------------------------------
restartSshSocket () {
  printComment 'Reloading systemd.'

  if ! systemctl daemon-reload; then
    printComment --error 'Failed to reload systemd.'

    return 1
  fi

  controlService 'restart' 'ssh.socket'
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script. A check is performed on the Linux
# distribution the host machine is running. If it is Ubuntu and higher than 
# 22.04 then the SSH socket is also configured. As per:
#
# - https://serverfault.com/a/1159600
#
# The new port is written to the setup config file, and the local ssh config is
# printed, before ssh is restarted. If the restart cuts the connection, the
# port is still recorded.
#
# Returns 1 as soon as a step fails.
#
# N.B.
# The socket is only restarted on Ubuntu higher than 22.04. As per:
#
# - https://askubuntu.com/a/1523872
# - https://askubuntu.com/a/1439482
#-------------------------------------------------------------------------------
mainScript () {
  local OS_DISTRIBUTION="$(getOsDistribution)"
  local SOCKET_TF=false

  if [ "$OS_DISTRIBUTION" = "ubuntu" ] && ! compareOsVersion '22.04'; then
    SOCKET_TF=true
  fi

  listDirectories "$SSHD_CONF_DIR_PATH"
  removeCurrentSshdConfigs || return 1

  checkSshdConfig || return 1
  createHardenedSshdConfig || return 1
  setPermissions --recursive '755' "$SSHD_CONF_DIR_PATH" '600' || return 1

  if [ "$SOCKET_TF" = true ]; then
    printComment 'You are on a version of Ubuntu that is higher than 22.04. We must also configure the SSH socket.'
    configureSshSocket || return 1
  fi

  writeSetupConfigOption "sshPort" "$SSH_PORT" || return 1
  printLocalSshConfig "$SSH_PORT"

  restartSsh "$SOCKET_TF"
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
