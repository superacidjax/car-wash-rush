# Car Wash Rush Architecture

## Trust boundaries

- The server owns coins, experience, inventory, durability, loot, vehicle completion, and teleports.
- Every client remote is rate-limited through `Remotes.connect` and validated again by its handler.
- Salvage prompts require a server-observed hold before rewards are calculated.
- A client may request an action; it never supplies the reward or authoritative result.

## Gameplay rules

Deterministic rules live in `src/shared/Domain` and receive explicit inputs, including random rolls. This keeps balancing logic independent from Roblox instances and makes boundaries easy to test.

- `ExperienceRules`: level requirements and multi-level awards.
- `InventoryRules`: durability, resale value, and quality charge.
- `InteractionRules`: timed interaction validation.
- `LootRules`: trashcan and dumpster outcomes.
- `PlotRules`: unlimited stable plot coordinates.
- `ProfileSchema`: profile defaults and migrations.
- `VehicleRules`: weighted vehicles, RV cadence, and non-repeating colors.

## Persistence

`ProfileStore` wraps Roblox DataStore operations with retries and a renewable session lease. Only the server holding the profile lease may save it. `PlayerData` snapshots a profile before saving and tracks an in-memory revision, so a mutation that occurs during a save remains dirty for the next save.

Studio may fall back to explicitly marked session-only data when DataStore access is unavailable. Published servers reject the player instead of risking an overwrite with a blank profile. Shutdown saves run concurrently within a fixed deadline.

Profile version 4 stores quality charge on each Quality Sponge. The migration assigns an old profile-wide charge to the equipped Quality Sponge, or the first one found.

## Inventory scale

All item copies are persisted as data. At most eight are materialized as Roblox `Tool` instances in the hotbar. The inventory controller can move any stored item into the hotbar or sell it for its server-calculated durability-adjusted value.

## World scale

Plots use deterministic grid allocation instead of a fixed eight-slot table. Workspace streaming is enabled with a 128-stud minimum radius and 512-stud target radius. The current greybox ground supports early scale testing; later city districts should be authored as streamable models rather than one permanent generated map.

## Client runtime

Client UI features are moving into controllers. Inventory and dirt highlighting are isolated today. Dirt highlights track only the prototype-car folder, not all Workspace descendants. Frame callbacks exist only while cleaning or while the Quality Sponge rainbow state is active; shop distance checks run five times per second.
