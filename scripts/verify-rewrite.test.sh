#!/usr/bin/env bash
# A force-push cannot be taken back, so the rewritten history is checked first: the
# old addresses are gone and nothing else changed. The "rewritten" repositories are
# replayed by hand rather than by git filter-repo, so the check does not share a
# mistake with the tool it checks.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
VERIFY="$HERE/verify-rewrite.sh"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
FAILED=0
OLD1=a@old-one.example OLD2=b@old-two.example OLD3=c@old-three.example NEW=klaus@vithanco.com

# build DIR VARIANT: three commits, tags v1 (after 1) and v2 (after 3).
# VARIANT: old | clean | miss-author | miss-committer | edit-file | drop-tag | drop-commit
build() {
    local dir=$1 v=$2 a1 a2 a3 c1 c2 c3
    a1=$OLD1 a2=$OLD2 a3=$OLD3
    if [ "$v" != old ]; then a1=$NEW a2=$NEW a3=$NEW; fi
    [ "$v" = miss-author ] && a2=$OLD2
    c1=$a1 c2=$a2 c3=$a3
    [ "$v" = miss-committer ] && c3=$OLD3
    git init -q "$dir"
    commit() { # author committer message
        GIT_AUTHOR_NAME=x GIT_AUTHOR_EMAIL=$1 GIT_COMMITTER_NAME=x GIT_COMMITTER_EMAIL=$2 \
        GIT_AUTHOR_DATE="2024-01-01T00:00:00Z" GIT_COMMITTER_DATE="2024-01-01T00:00:00Z" \
            git -C "$dir" commit -q -m "$3"
    }
    echo one > "$dir/f"; git -C "$dir" add -A; commit "$a1" "$c1" one; git -C "$dir" tag v1
    if [ "$v" != drop-commit ]; then
        echo two > "$dir/f"; git -C "$dir" add -A; commit "$a2" "$c2" two
    fi
    echo two > "$dir/f"
    if [ "$v" = edit-file ]; then echo THREE > "$dir/g"; else echo three > "$dir/g"; fi
    git -C "$dir" add -A; commit "$a3" "$c3" three
    [ "$v" = drop-tag ] || git -C "$dir" tag v2
}

# expect NAME EXIT [WORDS...]: run the verifier on old vs VARIANT
expect() {
    local name=$1 want=$2 variant=$3 out code
    shift 3
    rm -rf "$TMP/old" "$TMP/new"; build "$TMP/old" old; build "$TMP/new" "$variant"
    out=$("$VERIFY" "$TMP/old/.git" "$TMP/new/.git" "$OLD1" "$OLD2" "$OLD3" 2>&1); code=$?
    local ok=1
    [ "$code" -eq "$want" ] || ok=0
    for w in "$@"; do echo "$out" | grep -qF -- "$w" || ok=0; done
    if [ $ok -eq 1 ]; then echo "ok   $name"; else echo "FAIL $name (exit $code): $out" >&2; FAILED=1; fi
}

expect "Given a correct rewrite, when verified, then it passes" 0 clean
expect "Given a rewrite that missed one address, when verified, then it fails and names the address" 1 miss-author "$OLD2"
expect "Given an old address only in a committer field, when verified, then it fails" 1 miss-committer "$OLD3"
expect "Given a rewrite that changed a file at one tag, when verified, then it fails and names the tag" 1 edit-file v2
expect "Given a rewrite that dropped a tag, when verified, then it fails and names the tag" 1 drop-tag v2
expect "Given a rewrite that dropped a commit, when verified, then it fails" 1 drop-commit

exit $FAILED
