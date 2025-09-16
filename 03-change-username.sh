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
# . ./linshafun/host-information.sh
# . ./linshafun/initialisation.sh
# . ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
# . ./linshafun/ssh-config.sh
# . ./linshafun/ssh-keys.sh
# . ./linshafun/text.sh
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
# Checks for the existence of "tempuser".
#-------------------------------------------------------------------------------
checkForTempUser () {
  if id tempuser > /dev/null 2>&1; then
    echo "true"
  else
    echo "false"
  fi
}

#-------------------------------------------------------------------------------
# Create a temporary user, "tempuser", and adds it to sudoers so it can change
# the current users name and group.
#
# N.B.
# The "adduser" command uses "--gecos GECOS" to so that it only asks for a
# password for the new user during setup, rather than all the other information,
# as per:
#
# - https://unix.stackexchange.com/a/611219
#-------------------------------------------------------------------------------
createTempUser () {
  printComment 'Creating temporary user, "tempuser". You will be asked to enter a password for "tempuser" as part of this process.'
  printComment 'Set a password you can remember easily as you will need it shortly.' 'warning'
  printSeparator
  adduser --gecos GECOS tempuser
  printSeparator
  printComment '"tempuser" created. Adding to sudoers.'
  printSeparator
  adduser tempuser sudo
  printSeparator
  printComment '"tempuser" added to sudoers file.'
}

#-------------------------------------------------------------------------------
# Create a script in the temporary user directory to change the current logged
# in username and groupname to "$NEW_USER".
#-------------------------------------------------------------------------------
createTempUserScript () {
  printComment 'Creating a script to change the current username and group within the "tempuser" home directory at:'
  printComment "$RENAME_SCRIPT_PATH"
  cat <<EOF > "$RENAME_SCRIPT_PATH"
#!/bin/sh
echo "$COMMENT_PREFIX Changing username and group of the user $SUDO_USER."
usermod -l "$NEW_USER" "$SUDO_USER"
usermod -d /home/"$NEW_USER" -m "$NEW_USER"
groupmod --new-name "$NEW_USER" "$SUDO_USER"
echo "$COMMENT_PREFIX You can now log back in as the user $NEW_USER."
echo "$COMMENT_PREFIX Once logged in re-run:"
echo "$COMMENT_PREFIX cd linux-setup && sudo ~/linux-setup/03-change-username.sh"
EOF

  setPermissions "+x" "$RENAME_SCRIPT_PATH"
  setOwner "tempuser" "$RENAME_SCRIPT_PATH"

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
    printComment "To ensure that the current username can be changed, all processes currently being run by $SUDO_USER must be killed." 'warning'

    promptForUserInput 'Ready to kill all processes (y/n)?' 'This may log you out.'
    KILL_PROCESSES_YN="$(getUserInputYN)"

    if [ "$KILL_PROCESSES_YN" = true ]; then
      printSeparator
      printComment "Killing all processes for $SUDO_USER."
      printSeparator
      pkill -u "$SUDO_UID"

      exit
    else
      printSeparator
      printComment 'Processes remain running for this user. To enable changing the username, you must run the following command:' 'warning'
      printComment "pkill -u $SUDO_UID" 'warning'
      printSeparator

      exit
    fi
}

#-------------------------------------------------------------------------------
# Prints the instructions for using "tempuser" to change the current username.
#-------------------------------------------------------------------------------
printTempUserInstructions () {
  printComment 'You can now log this user out, log in as "tempuser", then run:'
  printComment "sudo ./$RENAME_SCRIPT."
  printSeparator
  printComment 'Finished setting up "tempuser".'
  printSeparator
}

#-------------------------------------------------------------------------------
# Removes the temporary user "tempuser' and it's home directory.
#-------------------------------------------------------------------------------
removeTempUser () {
  printComment 'Deleting temporary user "tempuser".'
  printSeparator
  deluser tempuser
  removeFileOrDirectory "$TEMPUSER_DIR_PATH"
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
#-------------------------------------------------------------------------------
mainScript () {
  local TEMPUSER_TF="$(checkForTempUser)"

  printComment 'Checking for a temporary user, "tempuser", used to enable changing the current username.'
  printComment "Check returned $TEMPUSER_TF."

  if [ "$TEMPUSER_TF" = "true" ]; then
    printComment '"tempuser" already exists.'

    removeTempUser

    finaliseScript "$CONFIG_KEY"
  elif [ "$TEMPUSER_TF" = "false" ]; then
    printComment '"tempuser" does not exist.'

    promptForUserInput 'Do you want to change the current users name (y/n)?' 'This will create a temporary user, "tempuser", to perform the change.'
    local CHANGE_NAME_YN="$(getUserInputYN)"
  fi
  
  if [ "$CHANGE_NAME_YN" = true ]; then
    createTempUser
    getNewUserName
    createTempUserScript

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
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript