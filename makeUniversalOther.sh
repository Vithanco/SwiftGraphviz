echo combining files for $1 
f="$(basename -- $1)"
lipo -create ./macOS/otherLibs/$f ./macOS_ARM/otherLibs/$f -output ./universal/$f
