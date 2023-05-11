#!/bin/sh

#-------------------------------------------------------------------------------
# Changes the current user's username by:
#
# 1. Creating a temporary user, `tempUser`;
# 2. Creating a script within their home directory to change the default ubuntu
#    username and groupname; and
# 3. Deleting the temporary user and their home directory.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Create a temporary user, `tempUser`, and adds it to sudoers so it can change
# the current users name and group.
#
# N.B.
# The `adduser` command uses `--gecos GECOS` to so that it only asks for a
# password for the new user during setup, rather than all the other information,
# as per:
#
# https://unix.stackexchange.com/a/611219
#-------------------------------------------------------------------------------
createTempUser () {
  echo "$COMMENT_PREFIX"'Creating temporary user, tempUser.'
  echo "$COMMENT_PREFIX"'N.B.'
  echo "$COMMENT_PREFIX"'Set a password you can remember easily as you will need it shortly.'
  echo "$COMMENT_SEPARATOR"
  adduser --gecos GECOS tempUser
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'Temporary user created. Adding to sudoers.'
  echo "$COMMENT_SEPARATOR"
  adduser tempUser sudo
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'Temporary user added to sudoers file.'
}

#-------------------------------------------------------------------------------
# Get the desired new username and group.
#-------------------------------------------------------------------------------
getNewUserName () {
  read -p "$COMMENT_PREFIX"'What is your new user name? ' NEW_USER
}

#-------------------------------------------------------------------------------
# Create a script in the temporary user directory to change the current logged
# in username and groupname to $NEW_USER.
#-------------------------------------------------------------------------------
createTempUserScript () {
  echo "$COMMENT_PREFIX"'Creating a script to change the current username and group within the tempUser'
  echo "$COMMENT_PREFIX"'home directory at /home/tempUser/renameUser.sh.'
  cat <<EOF > /home/tempUser/renameUser.sh
#!/bin/sh
echo "$COMMENT_PREFIX""Changing username and group of $SUDO_USER."
usermod -l $NEW_USER $SUDO_USER
usermod -d /home/$NEW_USER -m $NEW_USER
groupmod --new-name $NEW_USER $SUDO_USER
echo "$COMMENT_PREFIX""You can now log back in as $NEW_USER."
echo "$COMMENT_PREFIX""Once logged in run 03-change-username.sh again."
EOF

  echo "$COMMENT_PREFIX"'Script created. Please log in as tempUser and run the script with:'
  echo "$COMMENT_PREFIX"'./renameUser.sh.'
}

#-------------------------------------------------------------------------------
# Removes the temporary user `tempUser` and it's home directory.
#-------------------------------------------------------------------------------
removeTempUser () {
  echo "$COMMENT_PREFIX"'Deleting temporary user, tempUser.'
  echo "$COMMENT_SEPARATOR"
  deluser tempUser
  rm -r /home/tempUser
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'Temporary user and home folder deleted.'
}

#-------------------------------------------------------------------------------
# Check whether `tempUser` exists. If it doesn't exist, create it, or if it does
# exist, delete it.
#-------------------------------------------------------------------------------
checkForTempUser () {
  local TEMPUSER=echo $(cat /etc/passwd | grep tempUser)

  if [ -z TEMPUSER ]; then
    createTempUser
    getNewUserName
    createTempUserScript
    setPermissions "+x" "/home/tempUser/renameUser.sh"
    setOwner "tempUser" "/home/tempUser/renameUser.sh"
    echo "$COMMENT_PREFIX"'You can now log this user out, log in as tempUser, then run ./renameUser.sh.'
  else
    removeTempUser
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
checkForTempUser