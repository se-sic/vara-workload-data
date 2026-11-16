#!/usr/bin/env bash
# Builds the Pro Git Markdown benchmark used by cmark/md4c workloads.
#
# The base file is generated exactly like cmark's `make bench` target
# (bench/benchinput.md): all localizations of the first edition of Pro Git,
# concatenated. The base file is then repeated N times so that runtimes are
# long enough to be measured with GNU time.
#
# Usage: make_progit_bench.sh N...   (e.g., make_progit_bench.sh 50 150)
set -euo pipefail

PROGIT_COMMIT=61833a527c6ac0c44cc40793c034b81599c25efc
OUT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

git clone -q https://github.com/progit/progit.git "$WORK_DIR/progit"
git -C "$WORK_DIR/progit" checkout -q "$PROGIT_COMMIT"

BASE="$WORK_DIR/benchinput.md"
echo "" > "$BASE"
for lang in ar az be ca cs de en eo es es-ni fa fi fr hi hu id it ja ko mk nl \
    no-nb pl pt-br ro ru sr th tr uk vi zh zh-tw; do
  cat "$WORK_DIR"/progit/$lang/*/*.markdown >> "$BASE"
done

for n in "$@"; do
  name="progit-${n}x"
  for _ in $(seq "$n"); do cat "$BASE"; done > "$WORK_DIR/$name.md"
  # xz's 64 MiB dictionary (-9) captures the repetitions of the ~11 MB base
  tar -C "$WORK_DIR" --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
    -cf - "$name.md" | xz -9 -T1 > "$OUT_DIR/$name.tar.xz"
  rm "$WORK_DIR/$name.md"
done
