#!/bin/sh

#  docfixer.sh
#  Rubicon
#
#  Created by Galen Rhodes on 5/4/2020.
#  Copyright © 2020 ProjectGalen. All rights reserved.

for i in *.xcodeproj; do
    a=$(expr ${#i} - 10)
    PROJECT="${i:0:$a}"
done

TARGET="DocFixer"
USER="grhodes"
HOST="goober"
CONF="Release"

if [ ! -f "bin/DocFixer" ]; then
    xcodebuild -project "${PROJECT}.xcodeproj" -scheme "${TARGET}" -configuration "${CONF}" clean || exit $?
    xcodebuild -project "${PROJECT}.xcodeproj" -scheme "${TARGET}" -configuration "${CONF}" DSTROOT=. INSTALL_PATH=/bin install || exit $?
fi

bin/DocFixer "./${PROJECT}/Source" || exit $?
rsync -avz --delete-after docs/ "${USER}@${HOST}:/var/www/html/${PROJECT}/"
exit $?
