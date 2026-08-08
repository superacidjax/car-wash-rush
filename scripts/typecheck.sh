#!/usr/bin/env bash
set -euo pipefail

export PATH="${ROKIT_BIN:-$HOME/.rokit/bin}:$PATH"
mkdir -p build
definitions="build/robloxTypes.d.luau"
if [[ ! -f "$definitions" ]]; then
	curl -fsSL \
		https://luau-lsp.pages.dev/type-definitions/globalTypes.None.d.luau \
		-o "$definitions"
fi

mapfile_command=(find src -type f -name '*.luau' -print)
luau-lsp analyze \
	--platform=roblox \
	--definitions="$definitions" \
	--sourcemap=build/sourcemap.json \
	$("${mapfile_command[@]}")
