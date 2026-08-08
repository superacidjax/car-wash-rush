#!/usr/bin/env bash
set -euo pipefail

export PATH="${ROKIT_BIN:-$HOME/.rokit/bin}:$PATH"
studio="/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio"
mkdir -p build test-results
rojo build test.project.json --output build/car-wash-rush-tests.rbxlx
"$studio" \
	--task RunScript \
	--localPlaceFile "$(pwd)/build/car-wash-rush-tests.rbxlx" \
	--runScriptFile "$(pwd)/scripts/run-jest.luau" \
	--outputFile "$(pwd)/test-results/jest.log" \
	--quitAfterExecution
cat test-results/jest.log
grep -q "CAR_WASH_RUSH_TESTS_PASSED" test-results/jest.log
