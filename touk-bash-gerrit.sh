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
. "$TOUK_BASH_HOME/touk-bash-core.sh"

# Declares the review suffix and makes it available in global scope
# Args: no-arg
obtainReviewSuffix() {
    reviewSuffix="rev"
}

# Obtains the name of the review remote from git config and makes it available in global scope
# Args: no-arg
obtainReviewRemote() {
    reviewRemote=$(git config --get review.remote)
    if [ "$reviewRemote" == "" ]; then
        local actualRemote=$(git remote)
        warn "You don't have review.remote config option set in your git config."
        put "Your actual remote is $actualRemote, so what you probably need to do is:"
        put "    git config --add review.remote $actualRemote"
        exit 1
    fi
}

# Obtains the name of the review branch from git config and makes it available in global scope
# Args: no-arg
obtainReviewBranch() {
    reviewBranch=$(git config --get review.branch)
    if [ "$reviewBranch" == "" ]; then
        warn "You don't have review.branch config option set in your git config."
        put "It is probably master or develop so you can add it with:"
        put "    git config --add review.branch master"
        exit 1
    fi
}

# Obtains the review url from git config and makes it available in global scope
# Args: no-arg
obtainReviewUrl() {
    reviewUrl=$(git config --get review.url)
    if [ "$reviewUrl" == "" ]; then
        warn "You don't have review.url config option set in your git config."
        put "Set it to your gerrit HTTP url like http://review.example.com:"
        put "    git config --add review.url http://review.example.com"
        exit 1
    fi
}
