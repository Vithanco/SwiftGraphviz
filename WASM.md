# SwiftGraphviz on WebAssembly

Status of the effort to make SwiftGraphviz usable from WebAssembly, including
embedded-Swift-flavoured wasm.

## The key distinction: "embedded Swift" vs "Swift for WebAssembly"

These are different things and it matters for this library:

- **Swift SDK for WebAssembly (SwiftWasm)** — full Swift targeting
  `wasm32-unknown-wasi`. Real runtime, a Foundation subset, works with
  JavaScriptKit / BridgeJS for JS interop. **This is the realistic target.**
- **Embedded Swift** — a restricted dialect (no reflection, no metadata, no
  Foundation, restricted existentials). Can target `wasm32-unknown-wasi` *or*
  bare `wasm32-unknown-none`.

Graphviz is a large C library that needs libc: `malloc`, file I/O, `qsort`,
`setjmp`/`longjmp`, string functions, `getenv`. That rules out **bare-metal**
`wasm32-unknown-none` (no libc) without enormous shimming.

**Conclusion:** the viable path is **`wasm32-unknown-wasi`**, where wasi-libc
supplies what Graphviz needs. This works for both full SwiftWasm and embedded
Swift's WASI mode. Truly bare embedded (`-none`) is not realistic for Graphviz.

Because of this, the Swift layer has been made **Foundation-free and
embedded-friendly** (see below) — that code is a strict subset of what full
SwiftWasm needs, so it works for both.

## Three layers, three stories

| Layer | Wasm story |
|---|---|
| **CGraphviz** (C static lib) | The bulk of the work. Prebuilt `.a` binaries (xcframework, Linux bundle) are useless for wasm. Must cross-compile Graphviz to `wasm32-wasi` with the WASI SDK → new artifact bundle. Scaffolded in `build_wasm_static.sh`. |
| **GraphvizBridge** (C) | Trivial — pure C, compiles with the same WASI SDK. No changes needed. |
| **SwiftGraphviz** (Swift) | Done: made Foundation-free + `WASILibc` import branches added. |

## What has been done (verified natively)

- **Removed Foundation from the Swift target.** `GVGraph.asString` previously
  used a Foundation `Pipe` + `FileHandle` to capture `agwrite` output. That
  approach (a) pulled in Foundation, and (b) could **deadlock** once the DOT
  output exceeded the OS pipe buffer (~64 KB) because nothing drained the read
  end. It now uses POSIX `open_memstream`, which is Foundation-free, has no size
  limit, and exists on Darwin / glibc / musl / wasi-libc.
- **Added `#elseif canImport(WASILibc)` import branches** in `GVGraph`,
  `GVNode`, `GVEdge`, and `GVGeometry` (the last previously relied on math
  functions leaking through the C module — now explicit).
- **Dropped the unused `Codable` conformance** on `GVEdgeEnding` (Codable is
  unavailable in embedded Swift; it was never used).
- **Added tests** (`Tests/SwiftGraphvizTests/`) exercising `asString`, including
  a 5000-edge graph whose output exceeds the old pipe-buffer limit. Both pass
  natively. (The test target was previously misconfigured and ran nothing.)

## Graphviz → wasm: VERIFIED (2026-07-12, macOS arm64)

The gating experiment succeeded. The **entire Graphviz layout stack compiles to
`wasm32-unknown-wasip1`** (cdt, cgraph, gvc, common, pathplan, dotgen, neatogen,
+ core/dot_layout/neato_layout plugins) and merges into a **~2.4 MB
`libgraphviz.a`** exporting `agopen` / `agmemread` / `gvContext` / `gvLayout`.
A trivial malloc/stdio/`setjmp`/`longjmp` program built the same way linked and
**ran under V8** (Node) — the same engine class the browser uses.

Reproduce with `./build_wasm_static.sh` → produces `CGraphvizWasm.artifactbundle`.

**No wasi-sdk download needed:** the WASI sysroot (wasi-libc) ships inside an
installed Swift SDK for WebAssembly. The build auto-detects it under
`~/Library/org.swift.swiftpm/swift-sdks/*_wasm.artifactbundle/.../WASI.sdk`.

### The recipe (encoded in `wasm-toolchain.cmake` + `wasm_compat.h`)
The hurdles and their fixes, all now automated:

| Hurdle | Fix |
|---|---|
| `setjmp`/`longjmp` — wasm lowers it to the Exception Handling proposal; sysroot's `<setjmp.h>` `#error`s otherwise | compile with `-mllvm -wasm-enable-sjlj`; link with `-lsetjmp` |
| `<signal.h>` — wasi-libc has no real signals | `-D_WASI_EMULATED_SIGNAL`; link with `-lwasi-emulated-signal` |
| `flockfile`/`funlockfile` — absent in single-threaded wasi-libc | `wasm_compat.h` force-include provides no-op inlines |
| `read`/`write` undeclared in a core file | `wasm_compat.h` includes `<unistd.h>` globally |
| macOS `quartz` plugin (needs `Availability.h`) | disabled in the source patch |
| cmake `try_run`/link checks can't run wasm during cross-compile | `CMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY` (compile-only checks) |

### Runtime requirement
The wasm engine must enable the **Exception Handling** proposal (for SjLj).
Browsers (V8/JSC/SpiderMonkey) support the legacy EH form LLVM emits — this is
how Emscripten SjLj / `@hpcc-js/wasm` already run. Note: the `wasmtime` CLI (v46)
only implements the *standardized* EH, not the legacy form, so it can't run these
modules — use a browser or Node (V8) to test.

## Remaining work (next phase — integration)

The C library is done. What's left is compiling the Swift side for wasm and
wiring it into VGraph.

### 1. Compile SwiftGraphviz + GraphvizBridge for embedded wasm — DONE ✅
Both compile cleanly under **Embedded Swift** for `wasm32-unknown-wasip1`
(verified 2026-07-12 with `swift-6.3.3-RELEASE_wasm-embedded`):

```sh
GRAPHVIZ_WASM=1 swift build --swift-sdk swift-6.3.3-RELEASE_wasm-embedded
```

Package.swift wiring (all conditioned on `.wasi`):
- GraphvizBridge `cSettings`: `.define("_WASI_EMULATED_SIGNAL")` — Graphviz headers
  pull in `<signal.h>` via `types.h`.
- SwiftGraphviz `swiftSettings`: `-Xcc -D_WASI_EMULATED_SIGNAL` (propagates the
  define to the transitive CGraphviz/GraphvizBridge Clang **module** builds — a
  target's own cSettings don't reach dependency module compilation),
  `.enableExperimentalFeature("Embedded")`, `-wmo`.
- SwiftGraphviz `linkerSettings`: `.linkedLibrary("c++")` scoped to non-wasi.

Embedded-specific source changes made:
- `@MainActor func finishGraphviz()` → dropped under `#if os(WASI)` (no global
  actors in embedded; single-threaded anyway).
- Typed throws: `getPath()` and `EdgeLayout.init` now `throws(GraphvizError)`
  (embedded forbids `any Error`). `GraphvizError` made `public`; the redundant
  internal `LayoutError` was removed.
- `agwrite(self, UnsafeMutableRawPointer(f))` — on WASI `FILE` is opaque so
  `fopen`/`open_memstream` return `OpaquePointer`, which needs an explicit raw wrap.

### 1b. Link + run — VERIFIED ✅
A throwaway embedded-wasm executable that imports SwiftGraphviz, runs
`gvLayout(dot)`, and reads a node coordinate via the `.pos` Swift API **links and
runs under Node/V8**:

```
gvLayout rc=0
node a pos: 63.0,90.0
asString bytes: 77
OK  (wasi exit code: 0)
```

**Link recipe** for any executable/consumer that pulls in the Graphviz static lib
(this is what VGraph's wasi target needs):
- The consumer target (not just SwiftGraphviz) must pass
  `-Xcc -D_WASI_EMULATED_SIGNAL` if it imports GraphvizBridge/CGraphviz — the
  define is needed to build those Clang modules and does not propagate from the
  dependency.
- Link: `-lc++ -lc++abi`, and bump stack: `-Xlinker -z -Xlinker stack-size=1048576`.
- Fixed a real bug: `builtins.c` declared `textfont_dict_open` returning
  `struct _dt_s *`, but Graphviz declares it `void`. Harmless on native (linkers
  ignore return type) but **fatal on wasm** — a call-site/definition signature
  mismatch traps (`RuntimeError: unreachable`). Now matches (`void`).

**Two symbols the SDK's wasi-libc / libc++abi don't provide** (see decision below):
- `clock()` — wasi-libc omits it entirely; Graphviz `timing.c` uses it for
  profiling only. A `0`-returning stub is harmless.
- `__cxa_throw` / `__cxa_allocate_exception` / … — the SDK's `libc++abi` is built
  **without exceptions**, so these are absent. Only Graphviz's **VPSC** solver
  (C++, used by neato `ipsep`/DIGCOLA) throws. Dot/neato layout of well-formed
  graphs never reaches those throw sites.

**DECISION for production (VGraph): rebuild the wasm Graphviz lib without VPSC**
(disable `ipsep`/DIGCOLA in the cmake config) so there are no C++ exceptions and
no `__cxa_*` to resolve — cleaner than shipping aborting stubs. Fold this into the
phase-3 (15.1.0) rebuild. Until then, the smoke used aborting stubs for `__cxa_*`
plus a `clock()` stub (scratchpad only, not committed).

### 2. Package.swift wiring — done
`Package.swift` selects `CGraphvizWasm.artifactbundle` when `GRAPHVIZ_WASM` is
set (the manifest runs on the host and can't otherwise detect a wasm
cross-compile):

```sh
GRAPHVIZ_WASM=1 swift build --swift-sdk swift-6.3.3-RELEASE_wasm-embedded \
  -Xlinker -lsetjmp -Xlinker -lwasi-emulated-signal
```

### 3. VGraph integration
VGraph currently excludes SwiftGraphviz from wasm (`VGraphvizLib` is
macOS/iOS/linux-only; wasm uses `VGraphvizWasm` → host-side JS Graphviz). To get
the single self-contained module: make the `VGraphvizLib` in-process adapter
available on `.wasi` too (linking this artifact bundle), then retire the
JS round-trip in `VGraphvizWasm`. That's a VGraph-side change.

### 4. JS interop
VGraph already uses **BridgeJS** + JavaScriptKit. Once layout runs in-module, the
`dotForLayout` / `renderGraphWithLayout` split collapses into a single
`layout(dot) -> layoutJSON` (or straight to SVG) call — no external Graphviz.

## Toolchain notes
- This machine already has many Swift wasm SDKs (`swift sdk list`), including
  `swift-6.3.3-RELEASE_wasm-embedded`. Each bundle ships a `WASI.sdk` sysroot.
- clang/llvm-ar/llvm-nm from the swiftly Swift 6.3.3 toolchain target wasm fine.
