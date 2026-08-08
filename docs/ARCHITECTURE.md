# Car Wash Rush Architecture

## Trust boundaries

- The server owns coins, experience, inventory, durability, loot, vehicle completion, and teleports.
- Every client remote is rate-limited through `Remotes.connect` and validated again by its handler.
- Salvage prompts require a server-observed hold before rewards are calculated.
- A client may request an action; it never supplies the reward or authoritative result.

## Gameplay rules

Deterministic rules live in `src/shared/Domain` and receive explicit inputs, including random rolls. This keeps balancing logic independent from Roblox instances and makes boundaries easy to test.

- `ExperienceRules`: level requirements and multi-level awards.
- `CleaningRules`: cleaning-tool and vehicle tier compatibility.
- `InventoryRules`: durability, resale value, and quality charge.
- `InteractionRules`: timed interaction validation.
- `LootRules`: trashcan and dumpster outcomes, reward scaling, and round-up behavior.
- `PlotRules`: unlimited stable plot coordinates.
- `ProfileSchema`: profile defaults and migrations.
- `VehicleRules`: weighted vehicles, RV cadence, and non-repeating colors.
- `OnboardingRules`: per-player starter-rag exceptions over shared depleted containers.
- `DemandRules`: deterministic cross-server city events and tool-aware payout modifiers.
- `CooperativeEventRules`: scaled phase goals and participation/token awards.
- `AssistanceRules`: owner permissions, helper wages, and cooperation bonuses.
- `ChaosRules`: first-session protection, chance, type selection, and no-consecutive cooldown.
- `AdvancedCleaningRules`: trace-distance progress with remainder carry.
- `ServerCapacityRules`: bounded prototype plot and aircraft-bay allocation.

## Persistence

`ProfileStore` wraps Roblox DataStore operations with retries and a renewable session lease. Only the server holding the profile lease may save it. `PlayerData` snapshots a profile before saving and tracks an in-memory revision, so a mutation that occurs during a save remains dirty for the next save.

Studio may fall back to explicitly marked session-only data when DataStore access is unavailable. Published servers reject the player instead of risking an overwrite with a blank profile. Shutdown saves run concurrently within a fixed deadline.

Profile version 7 stores quality charge on each Quality Sponge plus ladder placement, permanent travel unlocks, event tokens, assistance mode, and completed-car count. The quality-charge migration assigns an old profile-wide charge to the equipped Quality Sponge, or the first one found.

## Inventory scale

All item copies are persisted as data. At most eight are materialized as Roblox `Tool` instances in the hotbar. The inventory controller moves stored items into the hotbar. Selling is available only through Milo, requires a confirmation, and is revalidated by the server against player proximity and the current durability-adjusted value.

## World scale

Plots use deterministic grid positions with an intentional eight-player prototype cap. A ninth player is rejected before plot or aircraft allocation. Workspace streaming is enabled with a 128-stud minimum radius and 512-stud target radius. The cap can increase only after profiling a larger unique aircraft-bay layout.

The aircraft salvage yard is a gated level-2 district. Its salvage containers are shared and fixed in place, while planes, helicopters, dirt ownership, and ladder access are private to each player. Current cleaning tools are tier 1 and are rejected by the server for tier-2 aircraft.

## Client runtime

Client UI features are moving into controllers. Inventory, dirt highlighting, demand, cooperative events, and Studio development controls are isolated today. Dirt highlights track only the prototype-car folder, not all Workspace descendants. Frame callbacks exist only for active displays/minigames or the Quality Sponge rainbow state; shop distance checks run five times per second.

## Multiplayer events

City demand uses a deterministic 20-minute UTC slot. Every server, including a newly created one, derives the same event and end time without external infrastructure or a potentially missed message. The server applies the multiplier; the client receives a display snapshot only.

The cooperative bus is server-local and follows six ordered phases. The server owns phase order, proximity, action rate, contribution totals, combo state, and persistent token awards. Phase tokens are saved immediately so a timeout cannot remove earned rewards. The temporary event destination is free and exists only while the event is active.

Player wash assistance is Private by default and persists as Private, Friends, or Open. A dirt spot can have only one server-side cleaner claim. Helpers consume their own durability and receive server-generated wages; currency is never transferred out of the owner's balance.
