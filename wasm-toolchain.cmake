# wasm-toolchain.cmake
#
# CMake toolchain file for cross-compiling Graphviz to wasm32-unknown-wasip1
# using the WASI sysroot that ships INSIDE an installed Swift SDK for WebAssembly
# (no separate wasi-sdk download needed on macOS).
#
# Required cache vars (passed by build_wasm_static.sh via -D):
#   WASM_CLANG        — path to a wasm-capable clang (the host Swift toolchain's clang)
#   WASM_SYSROOT      — path to WASI.sdk inside the Swift wasm SDK artifactbundle
#   WASM_AR           — llvm-ar
#   WASM_RANLIB       — llvm-ranlib
#
# Proven working (2026-07-12) with:
#   - clang from swiftly's Swift 6.3.3 toolchain (Apple clang 21)
#   - WASI.sdk from swift-6.3.3-RELEASE_wasm.artifactbundle (triple wasm32-unknown-wasip1)
#   - a trivial malloc/stdio/setjmp/longjmp program compiled, linked (-lsetjmp), and ran under V8.

set(CMAKE_SYSTEM_NAME WASI)
set(CMAKE_SYSTEM_PROCESSOR wasm32)

set(CMAKE_C_COMPILER   "${WASM_CLANG}")
set(CMAKE_CXX_COMPILER "${WASM_CLANG}")
set(CMAKE_AR           "${WASM_AR}")
set(CMAKE_RANLIB       "${WASM_RANLIB}")

set(_wasm_common "--target=wasm32-unknown-wasip1 --sysroot=${WASM_SYSROOT}")
# Flags Graphviz needs on wasm:
#  -mllvm -wasm-enable-sjlj : Graphviz uses setjmp/longjmp; wasm lowers it to the
#      Exception Handling proposal. Required or the sysroot's <setjmp.h> #errors.
#  -D_WASI_EMULATED_SIGNAL  : common/types.h includes <signal.h>; wasi-libc has no
#      real signals, only opt-in emulation. Final SwiftPM link must add
#      -lwasi-emulated-signal (see WASM.md).
# wasm_compat.h (sits next to this toolchain file) force-included to supply the
# few POSIX bits wasi-libc omits (flockfile/funlockfile, unistd decls).
set(_wasm_defs "-mllvm -wasm-enable-sjlj -D_WASI_EMULATED_SIGNAL -include ${CMAKE_CURRENT_LIST_DIR}/wasm_compat.h")
set(CMAKE_C_FLAGS_INIT   "${_wasm_common} ${_wasm_defs}")
set(CMAKE_CXX_FLAGS_INIT "${_wasm_common} ${_wasm_defs}")

# We build a STATIC LIBRARY only — the final wasm link is done later by SwiftPM
# with the Swift SDK. Making cmake's compiler checks compile-only (STATIC_LIBRARY)
# avoids try_run() and the need for crt/builtins/libsetjmp during configure — the
# usual cross-compile stumbling blocks.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Don't search the macOS host for programs/libraries/headers.
set(CMAKE_FIND_ROOT_PATH "${WASM_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
