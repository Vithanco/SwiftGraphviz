// Include headers
/* #undef HAVE_FCNTL_H */
/* #undef HAVE_MALLOC_H */
#define HAVE_SEARCH_H
/* #undef HAVE_STAT_H */
#define HAVE_STRINGS_H
/* #undef HAVE_SYS_INOTIFY_H */
#define HAVE_SYS_IOCTL_H
#define HAVE_SYS_MMAN_H
#define HAVE_SYS_SELECT_H
#define HAVE_SYS_STAT_H
#define HAVE_SYS_TIME_H
#define HAVE_SYS_TYPES_H
/* #undef HAVE_SYS_VFORK_H */
#define HAVE_TERMIOS_H
#define HAVE_UNISTD_H
/* #undef HAVE_VFORK_H */
/* #undef HAVE_X11_INTRINSIC_H */
/* #undef HAVE_X11_XAW_TEXT_H */
#define HAVE_GETOPT_H

// Functions
#define HAVE_DRAND48
#define HAVE_CBRT
#define HAVE_GETPAGESIZE
#define HAVE_GETENV
#define HAVE_LRAND48
/* #undef HAVE_MALLINFO */
/* #undef HAVE_MALLOPT */
#define HAVE_MSTATS
#define HAVE_SETENV
#define HAVE_SETMODE
/* #undef HAVE_SINCOS */
#define HAVE_SRAND48
#define HAVE_VSNPRINTF

// Types
#define HAVE_SSIZE_T
#define HAVE_INTPTR_T

// Typedefs for missing types
#ifndef HAVE_SSIZE_T
typedef int ssize_t;
#endif

// Libraries
/* #undef HAVE_ANN */
#define HAVE_EXPAT
#define HAVE_LIBGD
/* #undef HAVE_ZLIB */

// Values
#define BROWSER "open"
#define DEFAULT_DPI 96
#define DEFAULT_FONTPATH "~/Library/Fonts:/Library/Fonts:;/Network/Library/Fonts:;/System/Library/Fonts"
#define GVPLUGIN_CONFIG_FILE "config6"
#define PACKAGE_VERSION "2.44.2~dev.20210109.0706"

// Conditional values
#define DARWIN
#define DARWIN_DYLIB
