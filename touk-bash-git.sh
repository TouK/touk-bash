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

# Includes
DIR="$(dirname "$(readlink -f "$0")")"
. "$DIR/touk-bash-core.sh"

SED_COMMAND=`which sed`
SORT_COMMAND=`which sort`
GIT_LOG_PRETTY_FORMAT="--pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=iso"

if [ `uname -s` == "Darwin" ]; then
    # In case you are running OS X 'sort' and 'sed' commands are different then GNU versions
    # You need to install gnu version of this commands which are named with g-prefix
    # You may install it with: 'brew install coreutils' and 'brew install gnu-sed'
    SED_COMMAND=`which gsed`
    SORT_COMMAND=`which gsort`
fi

# Verify if you have everything committed
# Args: no-arg
verifyEverythingIsCommitted() {
    gitCommitStatus=$(git status --porcelain)
    if [ "$gitCommitStatus" != "" ]; then
        warn  "You have uncommitted files."
        put "Your git status:"
        exe git status
        put "Sorry. Rules are rules. Aborting!"
        exit 1
    else
        put "You have everything committed. Fine."
    fi
}

# Verify if you have everything pushed
# Your branch must be pushed to origin and all of your commits must be pushed
# Args:
#   $1 - remote
#   $2 - branch
verifyEverythingIsPushed() {
    gitRemoteBranch=$(git ls-remote --heads --quiet | grep refs/heads/$2\$)
    if [ "$gitRemoteBranch" == "" ]; then
        warn "Your branch $2 is not pushed to $1. Aborting!"
        put "Fix it with: git push -u $1 $2"
        exit 1
    fi

    gitPushStatus=$(git cherry $1/$2 -v)
    if [ "$gitPushStatus" != "" ]; then
        warn "You have local commits that were NOT pushed."
        exe git cherry $1/$2 -v
        put "Sorry. Rules are rules. Aborting!"
        exit 1
    else
        put "You have everything pushed to $1/$2 branch. Fine."
    fi
}

# Verify if git hook exists and is executable
# $1 - hook filename
# $2 - Gerrit HTTP URL
verifyGitHookExists() {
    # Search up directory tree - http://stackoverflow.com/a/9377073/411905
    gitRoot=`pwd`;
    while [ "$gitRoot" != "/" ] ; do
        if [ `find "$gitRoot" -maxdepth 1 -name .git` ]; then
            break;
        fi
        gitRoot=`dirname "$gitRoot"`
    done
    if [ "$gitRoot" == "/" ]; then
        warn "Cannot find .git directory in your project. Is this git repository? Aborting!"
        put "Your current working directory is $(pwd)"
        exit 1
    fi
    hook="$gitRoot/.git/hooks/$1"
    if [ ! -f $hook ] ; then
        warn "Git hook $1 cannot be found. Aborting!"
        put "Was looking for $hook."
        put "You have to download commit-hook from your gerrit here:"
        put "    wget -N $2/tools/hooks/commit-msg -O $hook"
        exit 1
    fi
    if [ ! -x $hook ] ; then
        warn "Git hook $1 is not executable. Aborting!"
        put "Was looking at $hook."
        put "Fix it with:"
        put "    chmod +x $hook"
        exit 1
    fi
}

# $1 - base branch
# $2 - current branch
verifyBaseBranchIsMerged() {
    notMerged=$(git --no-pager log $2..$1 $GIT_LOG_PRETTY_FORMAT)
    if [ "$notMerged" != "" ]; then
        warn "These commits are not yet merged from $1 to your branch $2."
        echo "$notMerged"
        put "Fix it with: git merge $1"
        br
        put "Or you can continue if you're sane and you know what you're doing."
        confirm
    else
        put "You have fully merged $1 to your branch $2. Fine."
    fi
}

# $1 - base remote
# $2 - base branch
verifyBaseBranchIsUpToDate() {
    notMerged=$(git --no-pager log $2..$1/$2 $GIT_LOG_PRETTY_FORMAT)
    if [ "$notMerged" != "" ]; then
        warn "These commits are not yet merged from $1/$2 to your local from $2:"
        echo "$notMerged"
        put "Fix it with: git checkout $2 ; git pull --rebase"
        br
        put "Or you can continue if you're sane and you know what you're doing."
        confirm
    else
        put "You have fully pulled $1/$2 to your local $2. Fine."
    fi
}

# $1 - upstream name
verifyUpstreamExists() {
    remotes=$(git remote -v | grep ^$1 | head -n 1)
    if [ "$remotes" == "" ]; then
        warn "There is no remote with name $1. Aborting!"
        exe git remote -v
        printRemoteHelp
        exit 1
    fi

    remoteAddress=$(git remote get-url $1)

    put "You have remote $1 pointing to url $remoteAddress. Fine."
}

# $1 - branch name
# $2 - expected upstream name
verifyBranchOnUpstream() {
    actualUpstream=$(git config --get branch.$1.remote)
    if [ "$2" != "$actualUpstream" ]; then
        warn "Your branch $1 is tracking upstream $actualUpstream, but it needs to track $2. Aborting!"
        put "Fix it with git branch -u $2/$1 $1."
        exit 1
    fi

    put "Your branch $1 has upstream set to $2. Fine."
}

# Verify your git is committed and pushed
# Args:
#   $1 - remote
#   $2 - current branch
verifyCleanGit() {
    put "Your working branch is $2 on remote $1. Fine."
    verifyEverythingIsCommitted
    verifyEverythingIsPushed $1 $2
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
#   $1 - tag name
printChangelog() {
    put "This is changelog since last deploy. Send it to the client."
    twoLastTags=$(git show-ref --tags | grep $1 | tail -n 2)
    put "Two last tags are:"
    put "$twoLastTags"
    twoLastHashesInOneLine=$(echo $twoLastTags | awk '{print $1}'  | tr "\\n" "-");
    twoLastHashesInOneLineWithTwoDots=${twoLastHashesInOneLine/-/..};
    twoLastHashesInOneLineWithTwoDotsNoMinusAtTheEnd=$(echo $twoLastHashesInOneLineWithTwoDots | $SED_COMMAND 's/-$//');
    exe git --no-pager log --pretty=oneline --no-merges $GIT_LOG_PRETTY_FORMAT $twoLastHashesInOneLineWithTwoDotsNoMinusAtTheEnd
}

# $1 - base branch
# $2 - current branch
compareBranches() {
    put "Compare branch $1 with $2:"
    exe git --no-pager log $1..$2 $GIT_LOG_PRETTY_FORMAT --date=iso
    br
}
