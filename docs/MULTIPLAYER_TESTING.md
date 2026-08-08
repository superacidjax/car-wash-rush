# Car Wash Rush Multiplayer Test Manual

## Test environments

Use three distinct environments. They answer different questions.

1. **Local automated suite** checks deterministic rules, profile migrations, static types, generated-world structure, and server infrastructure without touching saved player data.
2. **Studio Server & Clients** runs one local server plus 2-8 simulated clients. Use it for contention, replication, ownership, disconnects, and performance.
3. **Private published test experience** uses real Roblox accounts and isolated DataStores. Use it for persistence, friends-only assistance, cross-device behavior, cross-server demand synchronization, and release acceptance.

Never enable Studio API access on the production experience. A test experience has a different universe and therefore isolated DataStores even when the code uses the same DataStore name.

## Create the private test experience

The adult studio owner should do this once.

1. Open the current Rojo-synced place in Studio.
2. Select **File > Publish to Roblox As...**. If that item is not in the macOS File menu, open the **Home** ribbon, add **Experience Settings** through the ribbon's `+` tool selector, and use the publishing control from Studio.
3. Choose **Create New Experience** under the Car Wash Rush studio/group.
4. Name it `Car Wash Rush - Internal Test` and keep access private.
5. Open that test experience in Studio, connect the Rojo plugin, sync the project, and publish it.
6. Open **Experience Settings > Security** and enable **Studio Access to API Services** only for this test experience. Save the setting.
7. In Creator Dashboard, open the test experience and grant each household tester **Play** access. Edit access is not required for ordinary playtests.
8. Keep the production experience's Studio API access disabled.

Roblox's current official DataStore guidance explicitly recommends a separate test version because Studio can access the same stores as live servers: <https://create.roblox.com/docs/cloud-services/data-stores>.

## Set the server maximum to eight

The code rejects a ninth player before allocating a plot or aircraft bay, but Roblox matchmaking must also be configured to stop at eight.

**Creator Dashboard route**

1. Open <https://create.roblox.com/dashboard/creations> and select the private test experience.
2. Open **Configure > Places**.
3. Select the start place marked with a star.
4. On **Basic Settings**, set **Maximum Players** to `8` and save.
5. Repeat this later for production only after the eight-player performance gate passes.

**Studio route when available**

1. Open **Experience Settings**.
2. Open the places list.
3. Use the start place's `...` menu and choose **Configure Place**.
4. Set the maximum player count to `8` and save.

The setting is place-level and cannot be changed by Luau at runtime. Roblox documents both the read-only `Players.MaxPlayers` property and the Configure Place route: <https://create.roblox.com/docs/reference/engine/classes/Players> and <https://create.roblox.com/docs/studio/experience-settings>.

## Studio test controls

The purple **TEST** button appears only in Studio play sessions. It cannot appear in a published server.

- **+5,000 Coins** grants local test currency.
- **Set Level 10** unlocks level-gated test paths.
- **Grant Old Rag** grants or adds a starter rag.
- **+50 Event Tokens** verifies token UI and persistence snapshots.
- **Grant Level 2 Hose** adds the hidden hold-to-rinse test tool without placing it in Milo's economy.
- **Start Bus Event** bypasses the eight-minute first-event wait.
- **Reset Profile** requires two clicks within four seconds. It resets the current Studio profile and can save when Studio API access is enabled, so use it only in the private test experience.

## Start a multi-client session

1. Connect Rojo and confirm the plugin reports the project is synced.
2. In Studio's test-mode dropdown, choose **Server & Clients**.
3. Select `2` clients for correctness testing or `8` for the load gate.
4. Press **Play** or `F7`.
5. Keep the server session visible for Output and switch between client windows to act as each player.
6. Use **End Session** from any simulation window to close the server and every client.

Roblox currently supports up to eight local simulated clients. It also supports changing the local test-player count during a session for join/leave tests: <https://create.roblox.com/docs/studio/testing-modes>.

## Two-player correctness run

Run every row from a fresh two-client Server & Clients session.

| Scenario | Procedure | Pass criteria |
| --- | --- | --- |
| Plot and vehicle ownership | Inspect both clients' home areas. Each tries the other's car while assistance is Private. | Plots, cars, and aircraft bays do not overlap. The non-owner cannot start cleaning. |
| Open assistance | Owner taps **HELP** until it reads Open. Helper equips a rag and cleans a different spot. | Helper spends their own durability and gets 10 spot XP. Both players can clean separate spots concurrently. |
| Same-spot contention | Both click the same dirt patch as nearly simultaneously as possible. | One client starts. The other sees that another player is cleaning the spot. The spot and rewards complete once. |
| Assisted completion | Helper cleans the final spot. | Owner gets normal completion coins/XP plus 10% cooperation coins. Helper gets a game-generated 30% wage plus spot XP. No account loses coins. |
| Private/Friends/Open | Cycle the owner's button through all modes. Use real accounts for Friends. | Private rejects everyone; Friends accepts Roblox friends only; Open accepts any player. The selected mode survives rejoin. |
| Shared can contention | Both hold Search on the same unsearched can. | Only the first accepted search consumes and receives shared coin loot. Both clients see the searched visual. |
| Per-player onboarding rag | Let Player A consume a can. With Player B still missing a rag, search that visibly emptied can. | B can roll only their onboarding rag. B cannot recreate A's shared coins and cannot retry the same can until refill. |
| Join during refill | Search the final shared can, then add/rejoin Player B during the three-second refill indication. | B sees refilling visuals and receives the same reset positions/state after refill. No duplicate reset occurs. |
| Simultaneous purchases | Grant both players coins, open Milo, and buy the same item at nearly the same moment. | Each purchase affects only that player's coins and inventory. Duplicate owned items remain distinct. |
| Disconnect while cleaning | Start a spot, then remove/close that client while the server remains running. Have the other player try that spot if assistance allows. | The disconnected player's claim is released; no reward is granted for unfinished work; the spot remains dirty. |
| Ladder authorization | Set both to Level 10 but buy/place a ladder for only one account. Test Aircraft travel from both. | Only the authorized account can use its aircraft access. Shared yard containers remain shared; aircraft dirt remains private. |
| Permanent travel | Buy each travel destination, disconnect, and rejoin the private test experience. | Purchased destinations remain unlocked and no longer charge coins. Home remains free. Event travel appears only while a bus event is active. |
| Saved inventory | Buy duplicate sponges, use durability, charge a Quality Sponge, disconnect, and rejoin. | Coins, level, XP, rag flag, assistance mode, event tokens, travel, every item copy, durability, and per-sponge charge restore correctly. |
| Cooperative bus | Start the event from **TEST**. Both travel to EVENT and alternate actions at every phase station. | Phases remain ordered. Progress is shared. Idle players earn nothing. Meaningful players retain phase tokens on timeout and earn completion/combo tokens on success. |
| Demand sync | Observe the demand banner in two clients. | Event name, modifier, and countdown match. Completion payout uses the shown modifier. |

## Eight-player performance run

Start **Server & Clients** with eight clients. Do not use a ninth client; the published place and runtime guard are intentionally capped at eight.

1. Confirm eight unique home plots and eight unique aircraft-yard bays.
2. Set every client to Level 10, grant rags, and spawn all private vehicles and aircraft.
3. Send four players to the shared dump and have them contend on cans and dumpsters.
4. Keep four players cleaning their own vehicles simultaneously.
5. Start the bus event and move all eight players to the event lot.
6. Have every player contribute to one phase, then leave two idle during the next phase.
7. Change the simulated client count during the run to test staggered join and leave behavior.
8. Repeat Home, Milo, Dump, Aircraft, and Event travel while Workspace streaming is active.
9. Run for at least 20 minutes, including one shared-container refill and two full vehicle replacements per active cleaner.

**Pass gate**

- No server or client errors, infinite yields, or DataStore ownership warnings.
- No overlapping plots, aircraft bays, cars, or ownership IDs.
- No duplicate shared loot, vehicle completion, wage, event-token, or purchase awards.
- Server memory reaches a stable plateau instead of growing after each vehicle or event cycle.
- Frame time recovers after travel and bus spawning; no client remains below 30 FPS on the target household hardware during ordinary play.
- Network receive/send does not continuously climb while players are idle.
- Event-state replication remains readable and the server never accepts more than the configured action rate.

Use Studio's performance Stats and MicroProfiler during this run. Also test with 50-150 ms inbound and outbound delay in **Studio Settings > Network** because real Roblox clients commonly have latency: <https://create.roblox.com/docs/projects/client-server>.

## Mixed mobile and desktop run

Studio device emulation is useful for layout checks, but finish this run with one real mobile device and one desktop account in the private published experience.

1. Desktop player uses mouse/keyboard; mobile player uses touch.
2. Confirm sprint, inventory, travel, assistance, Milo, and every cleaning UI fit without overlap.
3. During Pressure Wash, confirm the mobile player moves with Roblox's left joystick and aims with the separate right controller.
4. Hold the Spray button while aiming, then release the aiming touch.
5. Spray must stop immediately when aim is released. Camera shake must remain mild and must not move UI controls.
6. Rotate the mobile device and repeat in both orientations.

## Cross-server demand run

Studio clients share one server, so use the private published experience for this check.

1. Join with Account A.
2. From the Roblox server list, make Account B join a different server. A private server plus a normal server also works.
3. Compare the active demand event, description, modifier, and end time.
4. Complete a comparable vehicle in both servers.

Both servers must show the same demand window and apply the same modifier. Demand uses a deterministic UTC schedule, so a newly created server discovers the current event without relying on a missed MessagingService broadcast.

## Release evidence

For each release candidate, record:

- Commit SHA and published test-place version.
- `./scripts/test.sh` result and test count.
- Two-player matrix result.
- Eight-player 20-minute result.
- Desktop and mobile device models.
- Screenshots of client/server Stats at peak load.
- Every defect found, its GitHub issue, and the commit that fixed it.
