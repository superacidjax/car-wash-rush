#!/usr/bin/env bash
set -euo pipefail

./scripts/check.sh
./scripts/test-engine.sh
./scripts/test-world-smoke.sh
