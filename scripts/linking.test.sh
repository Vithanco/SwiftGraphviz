#!/usr/bin/env bash
# The Linux bundle is compiled with gcc against libstdc++; `-lc++` there fails the final
# link with undefined std:: symbols (every consumer, and `swift test` itself). Apple and
# wasm link libc++. Package.swift has no way to run in a unit test, so the manifest text
# is what is held to this; the real check is `swift test` on Linux.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
FAILED=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $*" >&2; FAILED=1; }

libs=$(grep -n 'linkedLibrary("c++"\|linkedLibrary("stdc++"' Package.swift)

# 1
if echo "$libs" | grep -E 'linkedLibrary\("stdc\+\+", *\.when\(platforms: *\[\.linux\]\)\)' >/dev/null; then
    pass 'Given Package.swift, when the C++ runtime is read, then Linux links libstdc++'
else fail "Linux does not link stdc++ only on Linux: $libs"; fi

# 2
if echo "$libs" | grep -E 'linkedLibrary\("c\+\+", *\.when\(platforms: *\[[^]]*\]\)\)' | grep -qv 'linux'; then
    pass 'Given Package.swift, when the C++ runtime is read, then libc++ is limited to the other platforms'
else fail "libc++ is not conditioned away from Linux: $libs"; fi

exit $FAILED
