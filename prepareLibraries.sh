INSTALLER_ROOT="/Users/klauskneupner/xcode/"
GVROOT="${INSTALLER_ROOT}/graphviz"
GVTARGET="${GVROOT}/dump"
PLATFORM_DEVELOPER_BIN_DIR="/usr/bin"
rm -f config.cache

export CFLAGS="-mmacosx-version-min=10.13 -arch x86_64 -arch arm64"
export CPPFLAGS=""
export CXXFLAGS="-mmacosx-version-min=10.13 -arch x86_64 -arch arm64"


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
   CXX="${PLATFORM_DEVELOPER_BIN_DIR}/clang++ " \
   OBJC="${PLATFORM_DEVELOPER_BIN_DIR}/clang" \
   LD="${PLATFORM_DEVELOPER_BIN_DIR}/ld"

make

#rm -rf ${GVTARGET}
#mkdir -p ${GVTARGET}
#find . -type f -name '*_C.a' -exec cp -i {} ${GVTARGET} \;
#find . -type f -name '*.h' -exec cp {} -i ${GVTARGET} \;
                                                                                                          
