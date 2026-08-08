#!/usr/bin/env bash
set -euo pipefail

export PATH="${ROKIT_BIN:-$HOME/.rokit/bin}:$PATH"
mkdir -p build
if [[ ! -d DevPackages ]]; then
	wally install
fi

rojo sourcemap default.project.json --output build/sourcemap.json
stylua --check src tests
selene src tests
./scripts/typecheck.sh
rojo build default.project.json --output build/car-wash-rush.rbxlx
rojo build test.project.json --output build/car-wash-rush-tests.rbxlx
