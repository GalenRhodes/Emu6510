#!/bin/bash

#  build.sh
#  Rubicon
#
#  Created by Galen Rhodes on 5/4/2020.
#  Copyright © 2020 ProjectGalen. All rights reserved.

for i in *.xcodeproj; do
    a=$(expr ${#i} - 10)
    PROJECT="${i:0:$a}"
done

TARGET="${PROJECT}"
USER="grhodes"
HOST="goober"
CONF="Release"
INST_DIR="${HOME}/Library/Frameworks"

xcodebuild -project "${PROJECT}.xcodeproj" -scheme "${TARGET}" -configuration "${CONF}" clean || exit $?
xcodebuild -project "${PROJECT}.xcodeproj" -scheme "${TARGET}" -configuration "${CONF}" DSTROOT=${HOME} SKIP_INSTALL=No install
exit $?
