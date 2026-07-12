// wasi_compat.c
//
// Definitions for libc functions that the WASI sysroot declares but does not
// provide, and that Graphviz's static library references. Only compiled for
// wasm; empty elsewhere. Lives in the bridge so downstream wasm consumers
// (e.g. VGraph) link cleanly without their own shim.

#if defined(__wasi__)

#include <time.h>

// wasi-libc declares clock() in <time.h> but ships no implementation.
// Graphviz's lib/common/timing.c calls it for optional profiling only, so a
// constant is harmless — layout results do not depend on it.
clock_t clock(void) { return (clock_t)0; }

#endif
