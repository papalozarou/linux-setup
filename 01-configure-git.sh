#!/bin/sh

#-------------------------------------------------------------------------------
# Set up git for current user by:
#
# 1. updating and upgrading packages;
# 2. asking for user details;
# 3. setting global git user;
# 4. setting global git email;
# 5. setting global branch to `main`;
# 6. generating an ssh key; 
# 7. adding the ssh key to the ssh agent; and
# 8. generating an ssh config file.
#
# N.B.
# This script needs to be run as `sudo`.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Set the ssh directory for the Linux user.
#-------------------------------------------------------------------------------
local SSH_DIR=/home/$SUDO_USER/.ssh
local SSH_CONF=$SSH_DIR/config
local SSH_KEY=$SSH_DIR/github

#-------------------------------------------------------------------------------
# Update and upgrade installed packages.
#-------------------------------------------------------------------------------
updateUpgrade

#-------------------------------------------------------------------------------
# Request user details to use in global git settings and when generating ssh key
# for Github.
#-------------------------------------------------------------------------------
echo "$COMMENT_PREFIX"'What global git username do you want to use with git? 'GIT_USERNAME
echo "$COMMENT_PREFIX"'What global git email do you want to use with git? 'GIT_EMAIL

#-------------------------------------------------------------------------------
# Set global git username and email, using above values.
#-------------------------------------------------------------------------------
echo "$COMMENT_PREFIX"'Setting global git username to '"$GIT_USERNAME"'.'
git config --global user.name $GIT_USERNAME

echo "$COMMENT_PREFIX"'Setting global git email to '"$GIT_EMAIL"'.'
git config --global user.email "$GIT_EMAIL"

#-------------------------------------------------------------------------------
# Set global default brand to `main`. 
#-------------------------------------------------------------------------------
echo "$COMMENT_PREFIX"'Setting global default brand to `main`.'
git config --global init.defaultBranch main

#-------------------------------------------------------------------------------
# Generate an ssh key for use with github.
#-------------------------------------------------------------------------------
echo "$COMMENT_PREFIX"'Generating an ssh key for use with Github at `~/.ssh/github.'
generateSshKey $SSH_KEY $GIT_EMAIL
chown -R $USR:$USR $SSH_KEY

#-------------------------------------------------------------------------------
# Start the `ssh-agent` and add the newly generated key to it.
#-------------------------------------------------------------------------------
echo "$COMMENT_PREFIX"'Adding the generated key to the ssh-agent.'
eval "$(ssh-agent -s)"
ssh-add $SSH_KEY

#-------------------------------------------------------------------------------
# Generate an ssh config file, and set the correct ownership and permissions.
#-------------------------------------------------------------------------------
echo "$COMMENT_PREFIX"'Generating ssh config file at `~/.ssh/config`'
cat <<EOF > $SSH_CONF
Host github.com
  Hostname github.com
  IdentityFile ~/.ssh/github
  IdentitiesOnly yes
EOF

echo "$COMMENT_PREFIX"'Setting correct permissions for `~/.ssh/config`.'
chmod 600 $SSH_CONF
chown -R $USR:$USR $SSH_CONF

#-------------------------------------------------------------------------------
# List git configuration and test ssh connection.
#-------------------------------------------------------------------------------
echo "$COMMENT_PREFIX"'Listing git configuration…'
git config --list

echo "$COMMENT_PREFIX"'Testing ssh connection to git, which should show a success message.'
ssh -T git@github.com

#-------------------------------------------------------------------------------
# Remind user to copy public ssh key to Github account.
#-------------------------------------------------------------------------------
echo "$COMMENT_PREFIX"'Git is now configured on this machine.'
echo "$COMMENT_PREFIX"'N.B.'
echo "$COMMENT_PREFIX"'Add the contents of `github.pub` to your Github account via:'
echo "$COMMENT_PREFIX"''`Settings > Access > SSH and GPG keys`'