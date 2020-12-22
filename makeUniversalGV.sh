echo combining files for $1 
#basename "$1"
f="$(basename -- $1)"
#echo "$f"
lipo -create ./macOS/gvLibs/$f ./macOS_ARM/gvLibs/$f -output ./universal/$f
