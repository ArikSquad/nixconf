#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
node --test config/caelestia/island/tests/state.test.cjs
nix flake update caelestia-shell
nix build 'path:.#caelestia-island'
