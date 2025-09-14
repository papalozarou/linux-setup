#!/bin/sh

#-------------------------------------------------------------------------------
# Changes the current user's username by:
#
# 1. Creating a temporary user, `tempuser`;
# 2. Creating a script within their home directory to change the default ubuntu
#    username and groupname; and
# 3. Deleting the temporary user and their home directory.
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
TEMPUSER_DIR="/home/tempuser"
RENAME_SCRIPT="renameUser.sh"
RENAME_SCRIPT_PATH="$TEMPUSER_DIR/$RENAME_SCRIPT"

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
  printComment 'Creating temporary user, tempuser. You will be asked to enter a password for the temporary user as part of this process.'
  printComment 'Set a password you can remember easily as you will need it shortly.' true
  printSeparator
  adduser --gecos GECOS tempuser
  printSeparator
  printComment 'Temporary user created. Adding to sudoers.'
  printSeparator
  adduser tempuser sudo
  printSeparator
  printComment 'Temporary user added to sudoers file.'
}

#-------------------------------------------------------------------------------
# Get the desired new username and group.
#-------------------------------------------------------------------------------
getNewUserName () {
  promptForUserInput 'What is your new user name?' 
  NEW_USER="$(getUserInput)"
}

#-------------------------------------------------------------------------------
# Create a script in the temporary user directory to change the current logged
# in username and groupname to "$NEW_USER".
#-------------------------------------------------------------------------------
createTempUserScript () {
  printComment 'Creating a script to change the current username and group within the tempuser home directory at:'
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

  listDirectories "$RENAME_SCRIPT_PATH"
  printComment 'Script created.'
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
    printComment "To ensure that the current username can be changed, all processes currently being run by $SUDO_USER must be killed." true

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
      printComment 'Processes remain running for this user. To enable changing the username, you must run the following command:' true
      printComment "pkill -u $SUDO_UID" true
      printSeparator

      exit
    fi
}

#-------------------------------------------------------------------------------
# Removes the temporary user "tempuser' and it's home directory.
#-------------------------------------------------------------------------------
removeTempUser () {
  printComment 'Deleting temporary user, tempuser.'
  printSeparator
  deluser tempuser
  removeFileOrDirectory "$TEMPUSER_DIR"
  printSeparator
  printComment 'Temporary user and home folder deleted.'
}

#-------------------------------------------------------------------------------
# Runs the main functions of the script, by checking whether "tempuser" exists. 
# If it does exist delete it, if it doesn't exist create it.
# 
# N.B.
# When the "tempuser" is created, all processes for the current user are 
# terminated, which may include the current ssh session.
#-------------------------------------------------------------------------------
mainScript () {
  if id tempuser; then
    removeTempUser
  else
    createTempUser
    getNewUserName
    createTempUserScript
    setPermissions "+x" "$RENAME_SCRIPT_PATH"
    setOwner "tempuser" "$RENAME_SCRIPT_PATH"
    printComment 'You can now log this user out, log in as tempuser, then run:'
    printComment "sudo ./$RENAME_SCRIPT."
    printSeparator
    printComment 'Finished setting up the temporary user.'
    printSeparator

    killProcesses
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"