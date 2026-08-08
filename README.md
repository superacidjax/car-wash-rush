# Car Wash Rush

Roblox/Rojo prototype for the car wash tycoon game.

## Current Prototype

This Phase 0 build now creates:

- A greybox starter city corner.
- A protected safe zone and personal Level 1 vehicle for every player.
- A 270-by-202-stud shared salvage dump with perimeter fencing, an open gate, trash piles, shared cans, and Level 5 dumpsters.
- Small cars, pickup trucks, and RVs with vehicle-specific dirt counts and completion rewards.
- A decaying click/tap-anywhere cleaning minigame.
- Persistent coins, rag discovery, unique tool copies, and durability.
- Roblox Backpack/hotbar tools with automatic equipping after purchase.
- A shop clerk, adventure-style dialogue, and a three-item shop.
- Unlimited 55% sprinting with Left Shift or the mobile sprint button.
- A top navigation bar for travelling Home, to Milo's Shop, or to the Salvage Dump.
- Persistent level and XP progression with a left-side progress display.
- Jumping disabled during the current prototype phase.

The purpose is to test the first gameplay loop: search, equip, clean, earn, shop, and improve cleaning efficiency.

## Required Tools

- Roblox Studio
- Rojo 7 server
- Rojo 7 Roblox Studio plugin

Rojo installation docs: https://rojo.space/docs/v7/getting-started/installation/

This machine currently has Rojo installed at:

```bash
rojo --version
```

Expected result:

```text
Rojo 7.6.0
```

The Rojo Studio plugin has also been installed with:

```bash
rojo plugin install
```

For future machines, the Rojo docs list two required pieces: the local Rojo server and the Roblox Studio plugin. They recommend installing the server with Rokit:

```bash
rokit add rojo-rbx/rojo
rokit install
```

After the Rojo server is installed, install the Studio plugin:

```bash
rojo plugin install
```

If you prefer not to use Rokit, download the prebuilt Rojo binary and Rojo 7 plugin from the official GitHub releases page linked from the Rojo docs.

## Run Locally

From this folder:

```bash
rojo serve
```

Then in Roblox Studio:

1. Open or create the private `Car Wash Rush Prototype` place.
2. Open the Rojo plugin.
3. Connect to the local Rojo server.
4. Press `Play`.

The scripts will generate the starter city block, shared supply shop, and player safe zones automatically when the server starts.

## Enable Persistent Saving In Studio

Car Wash Rush uses Roblox `DataStoreService`; AWS is not required. To test saving in Studio, first publish the experience, then open `File > Experience Settings > Security` and enable `Studio Access to API Services`. Keep this enabled only for a dedicated test experience so Studio cannot overwrite live player data.

If API access is unavailable, the game prints a warning and safely uses session-only data for that test run.

## Roblox Studio Test Checklist

In Play mode, verify:

- The player is moved to a labeled personal safe zone.
- Searching a can requires holding the interaction for six seconds.
- Searched cans become rusty and visibly messy until the dump refills.
- Before finding the rag, each can has a 40% rag chance, 20% chance for 10 coins, and 40% chance to be empty.
- After finding the rag, each can has a 60% chance for 10 coins, 30% chance for 30 coins, and 10% chance for 75 coins.
- After all 12 are searched, the cans visibly refill for three seconds and move to 12 newly selected positions.
- Looted cans are unavailable to every player until the shared set refills.
- Four shared dumpsters require Level 5 and ten seconds to search.
- Dumpsters refill independently after all four are looted and award 20 coins at 60%, 60 coins at 30%, or 150 coins at 10%.
- The car cannot be cleaned until the rag is found and equipped.
- Clicking a dirt patch opens the cleaning bar; clicking or tapping anywhere in the gameplay viewport fills it while it slowly decays.
- Moving away or changing tools resets the active spot's progress.
- A completed spot costs exactly one durability, regardless of tool speed.
- Dirt highlights appear only while the player is holding a cleaning tool.
- Every cleaned spot awards 10 XP.
- Normal vehicles roll 65% Small Car and 35% Pickup Truck.
- Small cars use the 3-7 spot distribution and award 25 coins plus 50 completion XP.
- Pickup trucks use 4 spots at 10%, 8-12 spots at 17% each, and 15 spots at 5%; completion awards 50 coins plus 60 XP. Every pickup includes one large roof spot, with all remaining spots on reachable outer panels.
- Each player receives an RV after every 7-11 normal vehicles; RVs use an equal random count from 15-20 spots and award 100 coins plus 100 XP. The RV has a larger detailed body with a sloped front, windows, door, awning, lights, roof unit, and larger wheels.
- Every new vehicle receives one of seven vivid rainbow colors and cannot repeat that player's immediately previous color.
- Other players can enter a safe zone but cannot clean its vehicle.
- Milo's dialogue opens a shop selling a 25-coin rag, 125-coin sponge, and 500-coin quality sponge.
- Purchased duplicates appear separately in the Roblox hotbar and persist with their own durability.
- The 75-durability Sponge awards 1 bonus coin per dirt spot.
- The Quality Sponge charges across cars and sessions; every 10 spots unlocks a persistent rainbow ability worth 40 coins.
- The top Home, Milo's Shop, and Salvage Dump buttons travel to server-approved destinations and are disabled while cleaning.
- Milo's dialogue and store close automatically beyond 22 studs.
- Location labels disappear at a distance so they do not crowd the city view.
- Level requirements grow by 25% and round up to the next 10.
- Left Shift increases movement speed by 55%, and jumping does nothing.

## Project Layout

```text
src/
  client/
    Main.client.luau
  server/
    Main.server.luau
    Systems/
      GreyboxStarterCorner.luau
      MovementSystem.luau
      PlayerData.luau
      PrototypeGameplay.luau
      Remotes.luau
  shared/
    Catalog.luau
    Config.luau
```

## Next Implementation Step

After the Studio checklist passes, the next step is a guided tutorial and first-session objective system: point the player toward the trashcans, teach equipping and cleaning, lead them to Milo, and record completion analytics for each onboarding step.
