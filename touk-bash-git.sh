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

# Include core
. "`dirname $0`/touk-bash-core.sh"

SED_COMMAND=`which sed`

if [ `uname -s` == "Darwin" ]; then
    # In case you are running OS X 'sort' and 'sed' commands are different then GNU versions
	# You need to install gnu version of this commands which are named with g-prefix
	# You may install it with: 'brew install coreutils' and 'brew install gnu-sed'
    SED_COMMAND=`which gsed`
fi

# Verify if you have everything committed
# Args: no-arg
verifyEverythingIsCommitted() {
    gitCommitStatus=$(git status --porcelain)
    if [ "$gitCommitStatus" != "" ]; then
        warn  "You have uncommited files."
        put "Your git status:"
        exe git status
        put "Sorry. Rules are rules. Aborting!"
        exit 1
    else
        put "You have everything commited. Fine."
    fi
}

# Verify if you have everything pushed
# Your branch must be pushed to origin and all of your commits must be pushed
# Args:
#   $1 - branch
verifyEverythingIsPushed() {
    gitRemoteBranch=$(git ls-remote --heads --quiet | grep refs/heads/$1\$)
    if [ "$gitRemoteBranch" == "" ]; then
        warn "Your branch $1 is not pushed to origin. Aborting!"
        put "Fix it with: git push -u origin $1"
        exit 1
    fi

    gitPushStatus=$(git cherry origin/$1 -v)
    if [ "$gitPushStatus" != "" ]; then
        warn "You have local commits that were NOT pushed."
        exe git cherry origin/$1 -v
        put "Sorry. Rules are rules. Aborting!"
        exit 1
    else
        put "You have everything pushed to origin/$1 branch. Fine."
    fi
}

# Tags your last commit with a date time tag
# Args:
#   $1 - tag prefix
tagLastCommit() {
    d=$(date '+%y-%m-%d_%H-%M-%S')
    tagName="$1_$d"
    put "Tagging git with tag $tagName"
    exe git tag $tagName
    exe git push --tags
}

# Prints changelog in a beautiful format
# Args:
#   $1 - branch name
printChangelog() {
    put "This is changelog since last deploy. Send it to the client."
    twoLastTags=$(git show-ref --tags | grep $1 | tail -n 2)
    put "Two last tags are:"
    put "$twoLastTags"
    twoLastHashesInOneLine=$(echo $twoLastTags | awk '{print $1}'  | tr "\\n" "-");
    twoLastHashesInOneLineWithTwoDots=${twoLastHashesInOneLine/-/..};
    twoLastHashesInOneLineWithTwoDotsNoMinusAtTheEnd=$(echo $twoLastHashesInOneLineWithTwoDots | $SED_COMMAND 's/-$//');
    exe git --no-pager log --pretty=oneline --no-merges --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=iso $twoLastHashesInOneLineWithTwoDotsNoMinusAtTheEnd
}

# Verify your git is committed and pushed
# Args:
#   $1 - current branch
verifyCleanGit() {
    put "Your working branch is $1"
    verifyEverythingIsCommitted
    verifyEverythingIsPushed $1
    put "Your git status looks fine. Continuing."
    br
}