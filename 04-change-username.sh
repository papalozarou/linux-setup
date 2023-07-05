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
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='changedUsername'

#-------------------------------------------------------------------------------
# Set the file variables for the rename script.
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
# https://unix.stackexchange.com/a/611219
#-------------------------------------------------------------------------------
createTempUser () {
  echoComment 'Creating temporary user, tempuser'
  echoComment 'N.B'
  echoComment 'Set a password you can remember easily as you will need it shortly'
  echoSeparator
  adduser --gecos GECOS tempuser
  echoSeparator
  echoComment 'Temporary user created. Adding to sudoers'
  echoSeparator
  adduser tempuser sudo
  echoSeparator
  echoComment 'Temporary user added to sudoers file'
}

#-------------------------------------------------------------------------------
# Get the desired new username and group.
#-------------------------------------------------------------------------------
getNewUserName () {
  read -r "$COMMENT_PREFIX"'What is your new user name? ' NEW_USER
}

#-------------------------------------------------------------------------------
# Create a script in the temporary user directory to change the current logged
# in username and groupname to "$NEW_USER".
#-------------------------------------------------------------------------------
createTempUserScript () {
  echoComment "Creating a script to change the current username and group within the tempuser home directory at $RENAME_SCRIPT_PATH"
  cat <<EOF > "$RENAME_SCRIPT_PATH"
#!/bin/sh
echo "$COMMENT_PREFIX Changing username and group of the user $SUDO_USER."
usermod -l "$NEW_USER" "$SUDO_USER"
usermod -d /home/"$NEW_USER" -m "$NEW_USER"
groupmod --new-name "$NEW_USER" "$SUDO_USER"
echo "$COMMENT_PREFIX You can now log back in as the user $NEW_USER."
echo "$COMMENT_PREFIX Once logged in re-run:"
echo "$COMMENT_PREFIX sudo ~/linux-setup/04-change-username.sh"
EOF

  echoSeparator
  ls -lna "$RENAME_SCRIPT_PATH"
  echoSeparator
  echoComment 'Script created'
}

#-------------------------------------------------------------------------------
# Kills all processes currently being run by `$SUDO_USER`. This is done to
# ensure that the name of `$SUDO_USER` can be changed by `tempUser`.
#-------------------------------------------------------------------------------
killProcesses () {
    echoComment "To ensure that the current username can be changed, all processes currently being run by $SUDO_USER must be killed"
    echoSeparator
    echoComment 'Warning: This will log you out'
    echoSeparator
    read -r "$COMMENT_PREFIX Ready to kill all processes (y)?" KILL_PROCESSES_YN

    if [ "$KILL_PROCESSES_YN" = 'y' -o "$KILL_PROCESSES_YN" = 'Y' ]; then
      echoSeparator
      echoComment "Killing all processes for $SUDO_USER"
      echoSeparator
      pkill -u "$SUDO_UID"
    else
      echoSeparator
      echoComment 'You must answer y or Y to proceed'
      echoSeparator

      killProcesses
    fi
}

#-------------------------------------------------------------------------------
# Removes the temporary user "tempuser' and it's home directory.
#-------------------------------------------------------------------------------
removeTempUser () {
  echoComment 'Deleting temporary user, tempuser'
  echoSeparator
  deluser tempuser
  rm -r "$TEMPUSER_DIR"
  echoSeparator
  echoComment 'Temporary user and home folder deleted'
}

#-------------------------------------------------------------------------------
# Check whether "tempuser" exists. If it does exist delete it, if it doesn't
# exist create it.
# 
# N.B.
# When the "tempuser" is created, all processes for the currnet user are 
# terminated, including the current ssh session.
#-------------------------------------------------------------------------------
checkForTempUser () {
  if id tempuser; then
    removeTempUser
  else
    createTempUser
    getNewUserName
    createTempUserScript
    setPermissions "+x" "$RENAME_SCRIPT_PATH"
    setOwner "tempuser" "$RENAME_SCRIPT_PATH"
    echoComment "You can now log this user out, log in as tempuser, then run sudo ./$RENAME_SCRIPT"
    echoSeparator
    echoComment 'Finished setting up the temporary user'
    echoSeparator

    killProcesses
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#
# N.B.
# There is no "mainScript" here as we only run a single function.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
checkForTempUser
finaliseScript "$CONFIG_KEY"