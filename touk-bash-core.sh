#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# This is a part of touk-bash.
# Developed by TouK.

LAST_EXIT_STATUS=0
LAST_COMMAND=""

# Informative output indented line with yellow color
# Args:
#   $@ - many args
# Example:
#   put "Checking your repository status..."
put() {
  echo -e "\033[33m  >> $@\033[0m"
}

# Informative output indented line with green color
# Args:
#   $@ - many args
# Example:
#   green "Everything is fine!"
green() {
  echo -e "\033[32m  >> $@\033[0m"
}


# Warning output indented line with red color
# Args:
#   $@ - many args
# Example:
#   warn "You have uncommited files and it's unsafe to switch branch!"
warn() {
  echo -e "\033[31m  >> $@\033[0m"
}

# Display empty line
# Args: no-arg
# Example:
#   br
br() {
  echo ""
}

# Display horizontal line
# Args: no-arg
# Example:
#   hr
hr() {
  put "-----------------------------------------------------------------------------------------------------------------"
}

# Output a command, execute it and exit if it has failed
# Args:
#   $@ - many args
# Example:
#   exe ls -lha
exe() {
  echo -e "\033[36m   $ $@\033[0m"
  LAST_COMMAND="$@"
  "$@" 2>&1
  LAST_EXIT_STATUS=$?
  exitIfLastCommandFailed
}

# Execute a command without printing it and exit if it has failed
# Args:
#   $@ - many args
# Example:
#   quietExe ls -lha
quietExe() {
  LAST_COMMAND="$@"
  "$@" 2>&1
  LAST_EXIT_STATUS=$?
  exitIfLastCommandFailed
}

# Ask user if he wants to proceed further, otherwise exit
# Args: no-arg
# Example:
#   warn "You have uncommited files and it's unsafe to switch branch!"
#   confirm
confirm() {
    br
    read -e -r -p "     Are you sure? (type Yes to confirm) " response
    case $response in
        [yY][eE][sS])
            put "Confirmation accepted."
            br
            ;;
        *)
            put "Aborting."
            exit 0
            ;;
    esac
}

# Checks if there are sufficient args otherwise executes printHelp
# Relies on printHelp function
# Args:
#   $1 actual args count
#   $2 expected minimal args count
# Example:
#   checkArgs $# 1
checkArgs() {
    if [ $1 -lt $2 ]; then
        warn "Not enough arguments. You need to provide at least $2."
        printHelp
        exit 0
    fi
}

# Checks status of last executed command and exits if it was non-zero
# It is mainly used by exe and quietExe, you don't need to call it.
# Args: no-arg
exitIfLastCommandFailed() {
  if [ "$LAST_EXIT_STATUS" != "0" ]; then
    warn "Last executed command was: $LAST_COMMAND"
    warn "Last executed command exited with status $LAST_EXIT_STATUS"
    warn "Aborting!"
    exit $?
  fi
}

