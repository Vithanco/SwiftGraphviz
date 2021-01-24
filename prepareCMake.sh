#!/bin/sh -x

#  prepareCMake.sh
#  SwiftGraphviz
#
#  Created by Klaus Kneupner on 31/12/2020.
#  Copyright © 2020 Klaus Kneupner. All rights reserved.

INSTALLER_ROOT="~/xcode/"
GVROOT="~/Downloads/graphviz-master/"
GVTARGET="${GVROOT}_build/"
PLATFORM_DEVELOPER_BIN_DIR="/usr/bin"
GETTEXT_ROOT="~/Downloads/gettext-0.21"

CC="/Library/Developer/CommandLineTools/usr/bin/clang"
 #  CPP="${PLATFORM_DEVELOPER_BIN_DIR}/clang -E"
CXX="/Library/Developer/CommandLineTools/usr/bin/clang++ "
#   OBJC="${PLATFORM_DEVELOPER_BIN_DIR}/clang"
#   LD="${PLATFORM_DEVELOPER_BIN_DIR}/ld"

#echo "delete ${GVTARGET} ###############"
#rm -rf ${GVTARGET}


#${GETTEXT_ROOT}/configure --enable-static \
    CC="clang -arch arm64 -arch x86_64" \
    CXX="clang++ -arch arm64 -arch x86_64" \
    CPP="clang -E" CXXCPP="g++ -E"
    
#${GETTEXT_ROOT}/make
#${GETTEXT_ROOT}/make install

echo "cmake ################"
cmake -G Xcode -H${GVROOT} -B${GVTARGET} "-DCMAKE_C_COMPILER=${CC}" "-DCMAKE_CXX_COMPILER=${CXX}" -DENABLE_LTDL=NO "-DCMAKE_OSX_ARCHITECTURES=arm64" -Denable-static=yes -Denable-shared=no -Denable-ltdl=yes -Dwith-pangocairo=no -Dwith-visio=no -Dwith-quartz=no -Dwith-fontconfig=no

echo "xcodeBuild ###########"
xcodebuild -target cgraph -project ${GVTARGET}Graphviz.xcodeproj/ -arch x86_64 -arch arm64 -DONLY_ACTIVE_ARCH=NO
