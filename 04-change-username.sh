#!/bin/sh

#-------------------------------------------------------------------------------
# Changes the current user's username by:
#
# 1. checking for the existence of a temporary user, "tempuser";
# 2. asking the user if they want to change the current username;
# 3. creating "tempuser" and adding it to sudoers;
# 4. creating a script within the "tempuser" home directory to change the 
#    current username and groupname; and
# 5. removing "tempuser" and its home directory if it exists;
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
# . ./linshafun/host-information.sh
# . ./linshafun/host-initialisation.sh
# . ./linshafun/initialisation.sh
# . ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-config.sh
# . ./linshafun/ssh-keys.sh
. ./linshafun/text.sh
. ./linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='changedUsername'

#-------------------------------------------------------------------------------
# File variables.
#-------------------------------------------------------------------------------
TEMPUSER_DIR_PATH="/home/tempuser"
RENAME_SCRIPT="renameUser.sh"
RENAME_SCRIPT_PATH="$TEMPUSER_DIR_PATH/$RENAME_SCRIPT"

#-------------------------------------------------------------------------------
# The name of this script, for the instruction to run it again. It is
# "04-change-username.sh" on a Raspberry Pi and "03-change-username.sh"
# elsewhere, as "01-initialise-setup.sh" renames the scripts on other hosts.
#-------------------------------------------------------------------------------
SETUP_SCRIPT_NAME="$(basename "$0")"

#-------------------------------------------------------------------------------
# Checks for the existence of "tempuser".
#-------------------------------------------------------------------------------
checkForTempUser () {
  if id tempuser > /dev/null 2>&1; then
    echo true
  else
    echo false
  fi
}

#-------------------------------------------------------------------------------
# Create a temporary user, "tempuser", and adds it to sudoers so it can change
# the current users name and group.
#
# N.B.
# Returns 1 with an error if "tempuser" can't be created or added to the "sudo"
# group.
#
# N.B.
# The "adduser" command uses "--gecos GECOS" so that it only asks for a
# password for the new user during setup, rather than all the other information,
# as per:
#
# - https://unix.stackexchange.com/a/611219
#-------------------------------------------------------------------------------
createTempUser () {
  local STATUS=0

  printComment 'Creating temporary user, "tempuser". You will be asked to enter a password for "tempuser" as part of this process.'
  printComment --warning 'Set a password you can remember easily as you will need it shortly.'
  printSeparator
  adduser --gecos GECOS tempuser || STATUS=1
  printSeparator

  if [ "$STATUS" -ne 0 ]; then
    printComment --error 'Failed to create "tempuser".'

    return 1
  fi

  printComment '"tempuser" created. Adding to sudoers.'

  if ! adduser tempuser sudo; then
    printComment --error 'Failed to add "tempuser" to the "sudo" group.'

    return 1
  fi

  printComment '"tempuser" added to sudoers file.'
}

#-------------------------------------------------------------------------------
# Create a script in the temporary user directory to change the current logged
# in username and groupname to "$NEW_USER". The script also updates the nopasswd
# sudoers include file if present.
#
# The generated script uses "usermod" and "groupmod" commands as per:
#
# - https://serverfault.com/a/437343
#
# Returns 1 with an error if the script can't be written, or if its
# permissions or owner can't be set.
#-------------------------------------------------------------------------------
createTempUserScript () {
  local STATUS=0

  printComment 'Creating a script to change the current username and group within the "tempuser" home directory at:'
  printComment -- "$RENAME_SCRIPT_PATH"

  cat <<EOF > "$RENAME_SCRIPT_PATH" || STATUS=1
#!/bin/sh
echo "$COMMENT_PREFIX Changing username and group of the user $SUDO_USER."
usermod --login $NEW_USER --move-home --home /home/$NEW_USER $SUDO_USER
groupmod --new-name $NEW_USER $SUDO_USER
echo "$COMMENT_PREFIX Username and group changed from $SUDO_USER to $NEW_USER."

for SUDOERS_CONF_PATH in $SUDOERS_CONF_DIR_PATH/*; do
  if [ -f "$SUDOERS_CONF_PATH" ] && grep $SUDO_USER "$SUDOERS_CONF_PATH" > /dev/null; then
    sed -i "s/^$SUDO_USER[[:space:]]\+ALL=(ALL) NOPASSWD: ALL\$/$NEW_USER ALL=(ALL) NOPASSWD: ALL/" "$SUDOERS_CONF_PATH"
    echo "$COMMENT_SEPARATOR"
    grep $NEW_USER "$SUDOERS_CONF_PATH"
    echo "$COMMENT_SEPARATOR"
    echo "$COMMENT_PREFIX Updated sudoers file: $SUDOERS_CONF_PATH"
  fi
done

echo "$COMMENT_PREFIX You can now log back in as the user $NEW_USER, using the existing password."
echo "$COMMENT_PREFIX Once logged in re-run:"
echo "$COMMENT_PREFIX cd linux-setup && sudo ./$SETUP_SCRIPT_NAME"
EOF

  if [ "$STATUS" -ne 0 ]; then
    printComment --error "Failed to create the script at $RENAME_SCRIPT_PATH."

    return 1
  fi

  setPermissions "+x" "$RENAME_SCRIPT_PATH" || return 1
  setOwner "tempuser" "$RENAME_SCRIPT_PATH" || return 1

  listDirectories "$RENAME_SCRIPT_PATH"
  printComment 'Script created.'
}

#-------------------------------------------------------------------------------
# Get the desired new username and group.
#-------------------------------------------------------------------------------
getNewUserName () {
  promptForUserInput 'What is your new user name?' 
  NEW_USER="$(getUserInput)"
}

#-------------------------------------------------------------------------------
# Kills all processes currently being run by "$SUDO_USER". This is done to
# ensure that the name of "$SUDO_USER" can be changed by "tempUser".
#
# N.B.
# It is necessary to exit the script in both cases. Otherwise "finaliseScript" 
# will still run.
#-------------------------------------------------------------------------------
killProcesses () {
  printComment --warning "To ensure that the current username can be changed, all processes currently being run by $SUDO_USER must be killed."

  promptForUserInput 'Ready to kill all processes (y/n)?' 'This may log you out.'
  KILL_PROCESSES_YN=false
  if getUserInputYN; then KILL_PROCESSES_YN=true; fi

  if [ "$KILL_PROCESSES_YN" = true ]; then
    printSeparator
    printComment --warning "Killing all processes for $SUDO_USER."
    printSeparator
    pkill -u "$SUDO_UID"

    exit
  else
    printSeparator
    printComment --warning 'Processes remain running for this user. To enable changing the username, you must run the following command:'
    printComment --warning "pkill -u $SUDO_UID"
    printSeparator

    exit
  fi
}

#-------------------------------------------------------------------------------
# Prints the instructions for using "tempuser" to change the current username.
#-------------------------------------------------------------------------------
printTempUserInstructions () {
  printComment 'You can now log this user out, log in as "tempuser", then run:'
  printComment "sudo ./$RENAME_SCRIPT"
  printSeparator
  printComment 'Finished setting up "tempuser".'
  printSeparator
}

#-------------------------------------------------------------------------------
# Removes the temporary user "tempuser" and its home directory. Returns 1 if
# either can't be removed.
#-------------------------------------------------------------------------------
removeTempUser () {
  printComment 'Deleting temporary user "tempuser".'
  printSeparator

  if ! deluser tempuser; then
    printComment --error 'Failed to delete "tempuser".'

    return 1
  fi

  removeFilesOrDirectories --recursive "$TEMPUSER_DIR_PATH" || return 1
  printSeparator
  printComment '"tempuser" and home folder deleted.'
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script.
# 
# N.B.
# When the "tempuser" is created, all processes for the current user are 
# terminated, which may include the current ssh session.
# 
# If the user chooses not to change the username, the script exits and saves
# "changedUsername false" to the setup config file.
#
# Returns 1 as soon as a step fails.
#-------------------------------------------------------------------------------
mainScript () {
  printComment 'Checking for a temporary user, "tempuser", used to enable changing the current username.'
  local TEMPUSER_TF="$(checkForTempUser)"

  if [ "$TEMPUSER_TF" = true ]; then
    printComment '"tempuser" already exists.'

    removeTempUser || return 1

    finaliseScript "$CONFIG_KEY"
  elif [ "$TEMPUSER_TF" = false ]; then
    printComment '"tempuser" does not exist.'

    promptForUserInput 'Do you want to change the current users name (y/n)?' 'This will create a temporary user, "tempuser", to perform the change.'
    local CHANGE_NAME_YN=false
    if getUserInputYN; then CHANGE_NAME_YN=true; fi
  fi
  
  if [ "$CHANGE_NAME_YN" = true ]; then
    createTempUser || return 1
    getNewUserName
    createTempUserScript || return 1

    printTempUserInstructions

    killProcesses
  elif [ "$CHANGE_NAME_YN" = false ]; then
    printComment 'Leaving current username unchanged.'
    writeSetupConfigOption "$CONFIG_KEY" "false"

    printScriptFinished
    exit 1
  fi
}

#-------------------------------------------------------------------------------
# Run the script. "mainScript" calls "finaliseScript" itself once "tempuser" is
# removed. If "mainScript" fails, the script exits with 1, so the step isn't
# recorded as done in the setup config file and can be run again.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"

if ! mainScript; then
  printScriptExiting --changes
  exit 1
fi
