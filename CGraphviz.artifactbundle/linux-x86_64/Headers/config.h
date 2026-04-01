// Include headers
#define HAVE_SYS_INOTIFY_H
#define HAVE_SYS_IOCTL_H
#define HAVE_SYS_MMAN_H
#define HAVE_SYS_SELECT_H
#define HAVE_SYS_TIME_H
#define HAVE_GETOPT_H

// Functions
#define HAVE_DL_ITERATE_PHDR
#define HAVE_DRAND48
#define HAVE_INOTIFY_INIT1
#define HAVE_MEMRCHR
/* #undef HAVE_PANGO_FC_FONT_LOCK_FACE */
#define HAVE_SETENV
/* #undef HAVE_SETMODE */
#define HAVE_SRAND48
#define HAVE_STRCASESTR

// Typedefs for missing types
#ifdef _MSC_VER
#include <BaseTsd.h>
typedef SSIZE_T ssize_t;
#endif

// Libraries
/* #undef HAVE_DEVIL */
/* #undef HAVE_EXPAT */
/* #undef HAVE_FREETYPE */
/* #undef HAVE_LIBGD */
/* #undef HAVE_GD_PNG */
/* #undef HAVE_GD_JPEG */
/* #undef HAVE_GD_XPM */
/* #undef HAVE_GD_FONTCONFIG */
/* #undef HAVE_GD_FREETYPE */
/* #undef HAVE_LASI */
/* #undef HAVE_LIBZ */
/* #undef HAVE_GTS */
/* #undef HAVE_PANGOCAIRO */
/* #undef HAVE_POPPLER */
/* #undef HAVE_QUARTZ */
/* #undef HAVE_RSVG */
/* #undef HAVE_WEBP */

// Values
#define BROWSER "xdg-open"
#define DEFAULT_DPI 96
#define GVPLUGIN_CONFIG_FILE "config8"
#define PACKAGE_VERSION "14.1.5~dev.20260326.0520"

// Conditional values
/* #undef DARWIN */
/* #undef DARWIN_DYLIB */
