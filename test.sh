#!/bin/sh

#-------------------------------------------------------------------------------
# Import shared functions.
#-------------------------------------------------------------------------------
. ./00-shared-functions.sh

killProcesses () {
    echo "$COMMENT_PREFIX"'To ensure that the current username can be changed, all'
    echo "$COMMENT_PREFIX"'processes currently being run by '"$SUDO_USER"' must be killed.'
    echo "$COMMENT_SEPARATOR"
    echo "$COMMENT_PREFIX"'Warning: This will log you out.'
    echo "$COMMENT_SEPARATOR"
    read -p "$COMMENT_PREFIX"'Ready to kill all processes (y)?' KILL_PROCESSES

    if [ $KILL_PROCESSES = 'y' -o $KILL_PROCESSES = 'Y' ]; then
      echo "$COMMENT_SEPARATOR"
      echo "$COMMENT_PREFIX"'Killing all processes for '"$SUDO_USER"'.'
      echo "$COMMENT_SEPARATOR"
    else
      echo "$COMMENT_SEPARATOR"
      echo "$COMMENT_PREFIX"'You must answer y or Y to proceed.'
      echo "$COMMENT_SEPARATOR"

      killProcesses
    fi
}

killProcesses