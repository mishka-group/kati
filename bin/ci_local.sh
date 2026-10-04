#!/usr/bin/env bash
# What .github/workflows/test.yml checks, run here before a push.
#
# CI runs compile, `mix format --check-formatted` and `mix test` once, in
# whatever order its seed picks. This runs the same, with the suite in two
# random orders (`Kati.VersionTest` in it checks the Android and iOS build
# numbers agree; `mix kati.version --check` is for right before a tag, since it
# compares against today's date): a test that only
# passes after another one has left rows behind fails here too, rather than
# on the push.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "── compile ──"
mix compile --warnings-as-errors

echo "── format ──"
mix format --check-formatted

log="$(mktemp -t kati-ci)"
for run in 1 2; do
  seed=$((RANDOM * 32768 + RANDOM))
  echo "── tests, order $run (seed $seed) ──"
  if mix test --seed "$seed" > "$log" 2>&1; then
    grep -aE "^Result" "$log"
  else
    grep -aE "^\s+[0-9]+\) |^Result|^Failed" "$log"
    echo "FAILED with seed $seed — reproduce with: mix test --seed $seed (full log: $log)"
    exit 1
  fi
done

echo "── all CI checks pass ──"
