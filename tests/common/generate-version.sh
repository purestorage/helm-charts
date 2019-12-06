#!/usr/bin/env bash

# Copyright 2017, Pure Storage Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# First see if we are on a tag
MD5_BIN=md5sum
if [ `uname -s` == "Darwin" ]; then
    MD5_BIN=md5
fi

GIT_TAG=$(git describe --tags --exact-match 2> /dev/null)
MATCH_RESULT=$?

VERSION=""
if [[ "${MATCH_RESULT}" == 0 ]]; then
    VERSION="${GIT_TAG}"
else
    LATEST_TAG=$(git describe --abbrev=0 --tags 2> /dev/null)

    # If there are no tags to be found..
    if [[ -z "${LATEST_TAG}" ]]; then
        LATEST_TAG="unknown"
    fi

    CURRENT_REV=$(git rev-parse --verify HEAD | cut -c1-8)
    VERSION="${LATEST_TAG}-${CURRENT_REV}"
fi

diffHash() {
    { git diff --full-index; $(git ls-files --others --exclude-standard | while read -r i; do git diff --full-index -- /dev/null "$i"; done); } 2>&1 | \
    ${MD5_BIN} | cut -d ' ' -f 1 | cut -c1-8
}

if test -n "$(git status --porcelain)"; then
    VERSION+="-$(diffHash)"
fi

echo ${VERSION}
