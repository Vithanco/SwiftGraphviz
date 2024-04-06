This is everything that you need in order to create Mac App Store software that 
uses the Graphviz library. That means you can use this to:
- create Graphviz diagrams based on DOT files
- Use Graphviz as a library, by creating the representation of the graph in memory and as well receive the internal data structures from Graphviz back which allows you to use Graphviz as a lay-outer for your software.  



# Graphviz libraries
The normal build process for Graphviz is differently configured than needed. 
Therefore, you should use the https://github.com/Vithanco/graphviz together with this library. 
After cloning the package to your system, run ´./kkbuild.sh´ to prepare the build. You can then open the ´Graphviz.xcodeproj´ in XCode and compile.

The suggestion is that you use a ´graphviz´ library in the same directory as the ´SwiftGraphviz´ library (note capitals used).
In case that SwiftGraphviz doesn't automatically pick up the right libraries: this is the list of libraries included by default:
- liblabel.a
- libpatchwork.a
- libfdpgen.a
- libtwopigen.a
- librbtree.a
- libcircogen.a
- libcommon.a
- libdotgen.a
- libexpr.a
- libguplugin_core.a
- libguplugin_dot_layout.a
- libguplugin_neato_layout.a
- libgvplugin_quartz.a
- libgupr.a
- libneatogen.a
- libortho.a
- libosage.a
- libpack.a
- libpathplan.a
- libsfdpgen.a
- libsparse.a
- libxdot.a
- libgvc.a
- libcdt.a
- libcgraph.a

# Other libraries needed
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
