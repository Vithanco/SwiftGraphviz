This is everything that you need in order to create Mac App Store software that 
uses the Graphviz library. iOS software to follow. 

Currently this repository has committed the static libraries that are needed. 
I would like to change this towards the whole build pipeline. See needed 
libraries below. 

The source code in this uses the Eclipse Public License 1.0.  It is (to my 
knowledge) the same license as Graphviz uses and therefore choosen. 

Some of the compiled & included libraries use different licenses. So before 
using this software please review and accept licenses for the following software:
* iconv.o & libcharset.a - https://www.gnu.org/software/libiconv/
* libexpat.a - https://libexpat.github.io
* libglib-2.0.a - https://developer.gnome.org/glib/
* libgts.a - https://gts.sourceforge.io/
* libintl.a - https://www.gnu.org/software/gettext/
* libz.a - http://zlib.net/
