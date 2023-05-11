#!/bin/sh

#-------------------------------------------------------------------------------
# Changes the current user's username by:
#
# 1. Creating a temporary user, `tempuser`;
# 2. Creating a script within their home directory to change the default ubuntu
#    username and groupname; and
# 3. Deleting the temporary user and their home directory.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

#-------------------------------------------------------------------------------
# Create a temporary user, `tempuser`, and adds it to sudoers so it can change
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
  echo "$COMMENT_PREFIX"'Creating temporary user, tempuser.'
  echo "$COMMENT_PREFIX"'N.B.'
  echo "$COMMENT_PREFIX"'Set a password you can remember easily as you will need it shortly.'
  echo "$COMMENT_SEPARATOR"
  adduser --gecos GECOS tempuser
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'Temporary user created. Adding to sudoers.'
  echo "$COMMENT_SEPARATOR"
  adduser tempuser sudo
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
  echo "$COMMENT_PREFIX"'Creating a script to change the current username and group within'
  echo "$COMMENT_PREFIX"'the tempuser home directory at /home/tempuser/renameUser.sh.'
  cat <<EOF > /home/tempuser/renameUser.sh
#!/bin/sh
echo "$COMMENT_PREFIX""Changing username and group of the user $SUDO_USER."
usermod -l $NEW_USER $SUDO_USER
usermod -d /home/$NEW_USER -m $NEW_USER
groupmod --new-name $NEW_USER $SUDO_USER
echo "$COMMENT_PREFIX""You can now log back in as the user $NEW_USER."
echo "$COMMENT_PREFIX""Once logged in run:"
echo "$COMMENT_PREFIX""sudo ~/linux-setup/03-change-username.sh"
EOF

  echo "$COMMENT_SEPARATOR"
  ls -lna /home/tempuser | grep renameUser.sh
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'Script created.'
}

#-------------------------------------------------------------------------------
# Removes the temporary user `tempuser` and it's home directory.
#-------------------------------------------------------------------------------
removeTempUser () {
  echo "$COMMENT_PREFIX"'Deleting temporary user, tempuser.'
  echo "$COMMENT_SEPARATOR"
  deluser tempuser
  rm -r /home/tempuser
  echo "$COMMENT_SEPARATOR"
  echo "$COMMENT_PREFIX"'Temporary user and home folder deleted.'
}

#-------------------------------------------------------------------------------
# Check whether `tempuser` exists. I it does exist delete it, if it doesn't
# exist create it.
#-------------------------------------------------------------------------------
checkForTempUser () {
  if id tempuser; then
    removeTempUser
  else
    createTempUser
    getNewUserName
    createTempUserScript
    setPermissions "+x" "/home/tempuser/renameUser.sh"
    setOwner "tempuser" "/home/tempuser/renameUser.sh"
    echo "$COMMENT_PREFIX"'You can now log this user out, log in as tempuser, then run:'
    echo "$COMMENT_PREFIX"'sudo ./renameUser.sh.'
  fi
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
checkForTempUser