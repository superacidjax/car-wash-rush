#!/usr/bin/env bash
set -euo pipefail

export PATH="${ROKIT_BIN:-$HOME/.rokit/bin}:$PATH"
studio="/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio"
mkdir -p build test-results
rojo build default.project.json --output build/car-wash-rush.rbxlx
"$studio" \
	--task RunScript \
	--localPlaceFile "$(pwd)/build/car-wash-rush.rbxlx" \
	--runScriptFile "$(pwd)/scripts/run-world-smoke.luau" \
	--outputFile "$(pwd)/test-results/world-smoke.log" \
	--quitAfterExecution
cat test-results/world-smoke.log
grep -q '^CAR_WASH_RUSH_WORLD_SMOKE_PASSED$' test-results/world-smoke.log
