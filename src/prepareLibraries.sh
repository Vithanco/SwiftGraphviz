INSTALLER_ROOT="/Users/klauskneupner"
GVROOT="${INSTALLER_ROOT}/graphviz"  
GVTARGET="${INSTALLER_ROOT}/Documents/xcode/SwiftGraphviz/gvDump"
PLATFORM_DEVELOPER_BIN_DIR="/usr/bin"

./configure \
  --disable-dependency-tracking \
  --enable-shared=no \
  --enable-static=yes \
  --enable-ltdl=no \
  --enable-swig=no \
  --enable-tcl=no \
  -srcdir=/Users/klauskneupner/graphviz \
  --with-codegens=no \
  --with-cgraph=yes \
  --with-expat=no \
  --with-fontconfig=no \
  --with-freetype2=no \
  --with-ipsepcola=yes \
  --with-libgd=no \
  --with-xdot=yes \
 --with-quartz=yes \
  --with-visio=yes \
   --with-x=no \
   CC="${PLATFORM_DEVELOPER_BIN_DIR}/clang" \
   CPP="${PLATFORM_DEVELOPER_BIN_DIR}/clang -E" \
   CXX="${PLATFORM_DEVELOPER_BIN_DIR}/clang++" \
   OBJC="${PLATFORM_DEVELOPER_BIN_DIR}/clang" \
   LD="${PLATFORM_DEVELOPER_BIN_DIR}/ld" 

make

rm -rf ${GVTARGET}
mkdir -p ${GVTARGET}
find . -type f -name '*_C.a' -exec cp -i {} ${GVTARGET} \;
find . -type f -name '*.h' -exec cp {} -i ${GVTARGET} \;
                                                                                                          
