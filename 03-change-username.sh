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
# . ./linshafun/docker-volumes.sh
. ./linshafun/files-directories.sh
# . ./linshafun/firewall.sh
# . ./linshafun/host-env-variables.sh
# . ./linshafun/host-information.sh
# . ./linshafun/network.sh
. ./linshafun/ownership-permissions.sh
# . ./linshafun/packages.sh
# . ./linshafun/services.sh
. ./linshafun/setup-config.sh
. ./linshafun/setup.sh
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
  echoComment 'Creating temporary user, tempuser. You will be asked to enter a'
  echoComment 'password for the temporary user as part of this process.'
  echoNb 'Set a password you can remember easily as you will need it shortly.'
  echoSeparator
  adduser --gecos GECOS tempuser
  echoSeparator
  echoComment 'Temporary user created. Adding to sudoers.'
  echoSeparator
  adduser tempuser sudo
  echoSeparator
  echoComment 'Temporary user added to sudoers file.'
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
  echoComment 'Creating a script to change the current username and group within'
  echoComment 'the tempuser home directory at:'
  echoComment "$RENAME_SCRIPT_PATH"
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
  echoComment 'Script created.'
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
    echoComment 'To ensure that the current username can be changed, all processes'
    echoComment "currently being run by $SUDO_USER must be killed."

    promptForUserInput 'Ready to kill all processes (y/n)?' 'This may log you out.'
    KILL_PROCESSES_YN="$(getUserInputYN)"

    if [ "$KILL_PROCESSES_YN" = true ]; then
      echoSeparator
      echoComment "Killing all processes for $SUDO_USER."
      echoSeparator
      pkill -u "$SUDO_UID"

      exit
    else
      echoSeparator
      echoComment 'Processes remain running for this user. To enable changing the username,'
      echoComment 'you must run the following command:'
      echoComment "pkill -u $SUDO_UID"
      echoSeparator

      exit
    fi
}

#-------------------------------------------------------------------------------
# Removes the temporary user "tempuser' and it's home directory.
#-------------------------------------------------------------------------------
removeTempUser () {
  echoComment 'Deleting temporary user, tempuser.'
  echoSeparator
  deluser tempuser
  removeFileOrDirectory "$TEMPUSER_DIR"
  echoSeparator
  echoComment 'Temporary user and home folder deleted.'
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
    echoComment 'You can now log this user out, log in as tempuser, then run:'
    echoComment "sudo ./$RENAME_SCRIPT."
    echoSeparator
    echoComment 'Finished setting up the temporary user.'
    echoSeparator

    killProcesses
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"