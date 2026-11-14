#!/usr/bin/env bash
# Runs every test file headless. Needs: nvim >= 0.10 (0.11+ recommended), git. Optional: rg, fd, ImageMagick.
set -u
cd "$(dirname "$0")/.."
rc=0
echo "== main suite";   nvim --headless -u NONE -l tests/run.lua   || rc=1
echo "== images";       nvim --headless -u NONE -l tests/image.lua  || rc=1
echo "== layouts"
for sz in "200 60" "120 40" "80 24" "60 18" "45 14"; do
  set -- $sz
  FLY_COLS=$1 FLY_LINES=$2 nvim --headless -u NONE -l tests/layouts.lua || rc=1
done
exit $rc
