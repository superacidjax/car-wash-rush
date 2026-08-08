# Testing Car Wash Rush

## One-command local verification

From the repository root on a Mac with Roblox Studio installed:

```bash
./scripts/test.sh
```

This performs:

1. StyLua formatting verification.
2. Selene Roblox-aware linting.
3. Luau static type analysis against current Roblox API definitions and the Rojo sourcemap.
4. Production and test-place Rojo builds.
5. Jest execution inside the real Roblox Studio engine.
6. Production-world construction smoke testing inside Roblox Studio.

The engine wrapper requires the explicit `CAR_WASH_RUSH_TESTS_PASSED` marker because the Studio CLI can return process code 0 after a script error.

The world smoke runner starts the real greybox and gameplay systems, then verifies both salvage districts, the cooperative event lot and bus, all six event stations, fencing, ladder placement, fixed container counts, and catalog gates. It requires the `CAR_WASH_RUSH_WORLD_SMOKE_PASSED` marker.

## Fast checks

```bash
./scripts/check.sh
```

This is the cross-platform CI gate. It installs locked Wally dependencies when needed, then checks formatting, lint, sourcemaps, and both Rojo builds.

## Test layout

Tests are in `tests/*.spec.luau`. The test place maps only shared rules, server infrastructure, Wally's Jest packages, and tests. It does not start the live game or touch DataStores.

Current high-value coverage includes:

- XP rounding and multi-level progression.
- Loot probability boundaries and dumpster multipliers.
- Cleaning-tool tier compatibility and level-2 reward rounding.
- Durability, resale, and Quality Sponge charge.
- Vehicle weights, RV cadence, and color repetition.
- Profile migration and hotbar repair.
- Session locking, lease expiry, save ownership, and immutable snapshots.
- Remote token-bucket exhaustion and refill.
- Server-timed hold boundaries.
- Eight-player capacity and ninth-player allocation rejection.
- Per-player rag onboarding over shared depleted loot.
- Globally deterministic city-demand windows and modifiers.
- Cooperative event scaling, participation, and token boundaries.
- Assistance permissions, helper wages, and owner bonuses.
- Chaos protection/cooldown and sponge tracing distance.

## DataStore integration tests

Use a separate unpublished test experience. Never point automated tests at the production experience because Studio and live servers can share the same DataStore.

The next integration tier should use Roblox Open Cloud Luau Execution with adult-managed repository secrets. It should publish a temporary test place, run server/client smoke scenarios, and use a test-only DataStore name. Required secrets must be scoped only to the test universe and must never be committed.

## Manual multiplayer release check

Follow the repeatable [Multiplayer Test Manual](MULTIPLAYER_TESTING.md). It contains the private test-experience setup, exact two-player matrix, eight-player load gate, disconnect/rejoin tests, mixed mobile/desktop run, cross-server demand check, and evidence required for release.
