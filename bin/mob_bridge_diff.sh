#!/usr/bin/env bash
# Three-way diff for Kati's vendored native shell.
#
# There is no `mix mob.upgrade`. The app-owned Kotlin/C/Zig/plist files are
# generated once by `mix mob.new` and then diverge forever, while Mob ships a
# release every 1-3 days. This script is how a Mob bump becomes a merge instead
# of a rewrite.
#
# It generates a throwaway app with the CURRENT mob_new and compares three
# versions of every tracked file:
#
#   BASE    native/baseline/<pinned>/…   what upstream gave us originally
#   OURS    the working tree             base + Kati's fenced edits
#   THEIRS  /tmp/…/kati/…                what upstream gives us now
#
# A two-way diff cannot tell an upstream change from a Kati edit. That
# distinction is the entire point, which is why the baseline is committed.
#
#   bin/mob_bridge_diff.sh            report drift
#   bin/mob_bridge_diff.sh --merge    also write .merge files for conflicts
#   bin/mob_bridge_diff.sh --refresh  re-capture the baseline after an upgrade
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PIN_VERSION="$(grep -E '^mob_new=' native/UPSTREAM | cut -d= -f2)"
BASELINE="native/baseline/$PIN_VERSION"
MODE="${1:-report}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

tracked() { grep -vE '^\s*(#|$)' native/TRACKED; }

echo "── Generating a pristine app with the installed mob_new ──"
( cd "$WORK" && mix mob.new kati --dest "$WORK" --no-install >/dev/null 2>&1 ) \
  || { echo "mix mob.new failed — is the mob_new archive installed?"; exit 1; }
THEIRS="$WORK/kati"

NEW_VERSION="$(mix archive 2>/dev/null | grep -oE 'mob_new-[0-9.]+' | head -1 | cut -d- -f2)"
echo "   baseline pin : $PIN_VERSION"
echo "   installed    : ${NEW_VERSION:-unknown}"
echo

if [ "$MODE" = "--refresh" ]; then
  echo "── Refreshing baseline to $NEW_VERSION ──"
  NEW_BASE="native/baseline/$NEW_VERSION"
  rm -rf "$NEW_BASE"
  while read -r f; do
    [ -f "$THEIRS/$f" ] || { echo "  gone upstream: $f"; continue; }
    mkdir -p "$NEW_BASE/$(dirname "$f")"; cp "$THEIRS/$f" "$NEW_BASE/$f"
  done < <(tracked)
  echo "  wrote $NEW_BASE — now update native/UPSTREAM pins and re-run without --refresh"
  exit 0
fi

# Verify the baseline itself has not been edited. If it has, every three-way
# merge below is quietly wrong.
echo "── Verifying baseline integrity ──"
bad=0
while read -r line; do
  case "$line" in ''|\#*) continue;; esac
  sum="${line%% *}"; file="${line##*  }"
  [ -f "$BASELINE/$file" ] || continue
  actual="$(shasum -a 256 "$BASELINE/$file" | cut -d' ' -f1)"
  if [ "$sum" != "$actual" ]; then echo "  TAMPERED: $file"; bad=$((bad+1)); fi
done < native/UPSTREAM
[ "$bad" -eq 0 ] && echo "  baseline intact" || { echo "  $bad tampered file(s) — fix before merging"; exit 1; }
echo

clean=0; upstream_changed=0; conflicts=0
while read -r f; do
  ours="$f"; base="$BASELINE/$f"; theirs="$THEIRS/$f"
  [ -f "$ours" ]   || { echo "!! missing locally:  $f"; continue; }
  [ -f "$base" ]   || { echo "!! no baseline for:  $f"; continue; }
  [ -f "$theirs" ] || { echo "!! gone upstream:    $f  (Kati edits may be obsolete)"; continue; }

  kati_edits="$(grep -c 'KATI-BEGIN' "$ours" || true)"

  if cmp -s "$base" "$theirs"; then
    clean=$((clean+1))
    continue                      # upstream unchanged — Kati's edits still apply
  fi

  upstream_changed=$((upstream_changed+1))
  echo "── UPSTREAM CHANGED: $f  (${kati_edits} Kati edit(s)) ──"
  diff -u "$base" "$theirs" | head -40 || true

  if [ "$kati_edits" -gt 0 ]; then
    conflicts=$((conflicts+1))
    echo "   ^ this file carries Kati edits — review before taking upstream wholesale"
    if [ "$MODE" = "--merge" ]; then
      mkdir -p "$(dirname "$ours")"
      if git merge-file -p "$ours" "$base" "$theirs" > "$ours.merge" 2>/dev/null; then
        echo "   merged cleanly -> $ours.merge"
      else
        echo "   CONFLICTS -> $ours.merge (contains markers)"
      fi
    fi
  fi
  echo
done < <(tracked)

echo "── Summary ──"
echo "  unchanged upstream : $clean"
echo "  changed upstream   : $upstream_changed"
echo "  of those, with Kati edits : $conflicts"
[ "$conflicts" -gt 0 ] && echo "  run with --merge to produce .merge files"
exit 0
