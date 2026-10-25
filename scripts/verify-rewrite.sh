#!/usr/bin/env bash
# verify-rewrite.sh OLD NEW ADDRESS...
# OLD and NEW are git directories. Passes when NEW has none of the ADDRESSes as author or
# committer and is otherwise the same history: the same tags with the same trees, the
# same number of commits.
set -uo pipefail
[ $# -ge 3 ] || { echo "usage: $0 OLD NEW ADDRESS..." >&2; exit 2; }
OLD=$1 NEW=$2; shift 2
FAILED=0
fail() { echo "FAIL $*" >&2; FAILED=1; }

emails=$(git --git-dir="$NEW" log --all --format='%ae%n%ce')
for addr in "$@"; do
    echo "$emails" | grep -qxF -- "$addr" && fail "address still in history: $addr"
done

for tag in $(git --git-dir="$OLD" tag); do
    new_tree=$(git --git-dir="$NEW" rev-parse -q --verify "refs/tags/$tag^{tree}") \
        || { fail "tag missing: $tag"; continue; }
    old_tree=$(git --git-dir="$OLD" rev-parse "refs/tags/$tag^{tree}")
    [ "$old_tree" = "$new_tree" ] || fail "tree differs at tag: $tag"
done

old_count=$(git --git-dir="$OLD" rev-list --all --count)
new_count=$(git --git-dir="$NEW" rev-list --all --count)
[ "$old_count" = "$new_count" ] || fail "commit count differs: $old_count -> $new_count"

[ $FAILED -eq 0 ] && echo "ok: no listed address left; $old_count commits; tags and trees unchanged"
exit $FAILED
