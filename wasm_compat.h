// wasm_compat.h
//
// Force-included (clang -include) into every Graphviz C translation unit when
// cross-compiling to wasm32-wasi. Papers over the handful of POSIX facilities
// wasi-libc omits that Graphviz's layout code assumes. Only active under wasm.

#pragma once

#if defined(__wasi__)

#include <unistd.h>  // read/write/close — some core files call these without including it
#include <stdio.h>

// wasi-libc is single-threaded and does not provide stdio stream locking
// (flockfile/funlockfile/ftrylockfile). Graphviz's lib/util/lockfile.h calls
// them. Single-threaded => locking is a safe no-op.
#ifndef GV_WASM_STDIO_LOCK_SHIM
#define GV_WASM_STDIO_LOCK_SHIM 1
static inline void flockfile(FILE *f) { (void)f; }
static inline void funlockfile(FILE *f) { (void)f; }
static inline int ftrylockfile(FILE *f) { (void)f; return 0; }
#endif

#endif  // __wasi__
