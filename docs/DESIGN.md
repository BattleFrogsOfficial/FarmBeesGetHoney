# Farm Bees Get Honey — Game Design & Economy

Nov 4, 2026 · Legacy Cleaning

> Design intent and targets. The live numbers and how the code does it live in `CLAUDE.md`; any rule change goes here with a dated note *and* there, in the same commit.

## Overview

Farm Bees Get Honey is a Roblox merge-and-conveyor idle game modeled on Beaver Farm, with bees in place of beavers and honey jars in place of logs. You buy bees, merge them up a 12-tier ladder, and their honey rides a conveyor to a beekeeper whose processor turns it into money; reaching a high enough tier lets you prestige for a permanent 1.5x money bonus.

v1 scope rules:

- UI and HUD are bare-bones: flat solid-color frames and plain text, no icons, no polish. Effort goes into the 12 bee models and the jar visuals only.
- No luck system, no random bee purchases, no 2nd/3rd-bee hive upgrades, no selling hives, no offline earnings. Each of these was considered and cut.
- 6 players per server, one plot each, no interaction between plots.
- Repo: BattleFrogsOfficial/FarmBeesGetHoney.

## Core loop

One full cycle of play, in the order the player experiences it:

1. Step on a Buy pad (Buy 1 / Buy 5 / Buy 25). Each bee bought is the current shop tier and costs slightly more than the last. A hive box drops from above into the next free slot of the hive wall, bee inside.
2. Press E near the hive wall to merge. Every group of three same-tier hives collapses into one hive of the next tier, repeatedly, until nothing more can merge. The wall is then rebuilt from the bottom-left.
3. Each hive drops a jar of honey onto the conveyor every 8 seconds (Tier 1) with physics; the belt carries jars to its end. Jars that reach the end despawn and add their honey to a counter on the pickup pad. Max 50 live jars per plot.
4. Walk onto the pickup pad to collect all counted honey (or own Auto Collect).
5. Walk to the beekeeper stand and hand in honey. It goes into the processor queue, which converts a fixed amount of honey per second into money.
6. Spend money on more bees and processor levels; repeat.
7. Once you have created the required tier for your next prestige and can pay the prestige price, step on the Prestige pad: money, hives, processor level and shop tier reset; you keep gamepasses and gain a permanent, stacking 1.5x money multiplier. A flag above your plot shows your prestige number.

## Hive wall

Each plot has a fixed 10 wide by 10 high wall of hive slots (100), not upgradable, starting empty.

- Fill order: bottom row left to right, then the row above starting again at the far left, and so on up.
- Buying a bee drops a hive box from above into the next free slot (tween or physics drop, with a thud and a small dust puff).
- When a slot is vacated (by a merge), every box above it in that column falls straight down with gravity to close the gap. In practice the merge step rebuilds the whole wall (see Merge), so a column collapse is the visual, not the logic.
- Hives cannot be sold or removed. The only way a hive leaves the wall is by merging.
- Each hive shows its tier number and bee model; the box color steps with tier (plain wood at Tier 1 through a glowing dark box at Tier 12).
- If the wall is full (100 hives) and no merge is possible, the Buy pads are disabled with a "Wall full — press E to merge" message.

## Bees

Twelve bee tiers form a straight ladder; each tier's jar holds 5x the honey of the tier below. The bee models are the one place v1 spends visual effort: each tier needs its own recognizable build (size, color, wings, accessories), assembled from parts in Lua so the whole game ships from the repo.

| Tier | Bee | Honey per jar | Look (starting point) |
|---|---|---|---|
| 1 | Honey Bee | 1 | Small, classic yellow and black |
| 2 | Bumble Bee | 5 | Round, fuzzy, bigger |
| 3 | Carpenter Bee | 25 | Glossy black, blue sheen |
| 4 | Mason Bee | 125 | Metallic green |
| 5 | Sweat Bee | 625 | Metallic teal, slim |
| 6 | Leafcutter Bee | 3,125 | Carries a leaf |
| 7 | Mining Bee | 15,625 | Hard hat, dusty brown |
| 8 | Orchid Bee | 78,125 | Iridescent purple |
| 9 | Cuckoo Bee | 390,625 | Red and black, spiky |
| 10 | Giant Bee | 1,953,125 | Double size, armored |
| 11 | Royal Bee | 9,765,625 | Cape and crest |
| 12 | Queen Bee | 48,828,125 | Crown, glow, largest |

Shop and pads:

- Shop tier = highest tier you have ever created in this run minus 4, minimum 1. Creating Tier 6 moves the shop to Tier 2; Tier 12 puts it at Tier 8. Every new tier costs about 243 shop-tier bees (3 to the 5th, since the shop sits 5 steps below the tier being built).
- Three pads: Buy 1, Buy 5, Buy 25. Each charges the sum of the next N individual prices.
- Individual price = $5 x 5^(shop tier - 1) x 1.01^(bees bought at this shop tier). The count resets to 0 whenever the shop tier rises, so the first bee of a new shop tier is cheap relative to income.
- A pad shows its total price and greys out if unaffordable or if fewer than N slots are free.

## Merge

One press of E compacts the whole wall: three same-tier hives become one hive of the next tier, repeated until no tier has three or more. Merging is free and instant; Tier 12 never merges.

Algorithm (server-side, pure function on the list of hive tiers):

1. Count hives per tier.
2. For tier 1 up to 11: add floor(count / 3) to the tier above; keep count mod 3 at this tier.
3. Rebuild the wall from the bottom-left in ascending tier order (so leftovers of low tiers sit first, highest tiers last). Fill order is the normal one: bottom row left to right, then up.

Example: 10 Tier 1 hives. Step 2 gives 1 Tier 1 and 3 Tier 2, then 1 Tier 1, 0 Tier 2 and 1 Tier 3. Result: wall holds [1, 3] in the first two slots.

Presentation: hives lift, fly to a merge point in front of the wall, flash, and the new hive drops into place; then the wall rebuilds with the gravity fall. Keep it under 1.5 seconds no matter how many merges happen. The E prompt appears when the player is within the plot and at least one merge is possible; Auto Merge (gamepass) presses it every 10 seconds.

## Honey jars and conveyor

Every hive drops one jar every 8 seconds onto the conveyor behind the wall; the jar is a physics cylinder (no corners, nothing jams) carrying a honey amount and an optional variant.

- Honey amount = the hive tier's honey per jar (table above) x the variant multiplier.
- Variants roll per jar at creation: Shiny 2% (x2), Golden 0.5% (x5), Rainbow 0.05% (x20), Quantum 0.005% (x100). One variant max per jar. Lucky Jars (gamepass) triples these odds.
- Jar visuals step by tier: plain glass (1 to 3), fuller jar with a tag (4 to 6), gold lid (7 to 9), gem-studded lid and a glow (10 to 12). Variants add a tint and a particle: silver sparkle, gold shimmer, rainbow trail, purple static.
- Belt: around 6 seconds end to end, moved by a velocity surface rather than per-jar scripting. Cap of 50 live jars per plot (35 until 2026-11-04); a hive whose jar would exceed the cap holds it until a jar leaves the belt.
- Jars that reach the end despawn and add their honey to the pickup pad's counter ("Honey: 12,450 — walk here"). Stepping on the pad collects it all. Auto Collect (gamepass) collects continuously.

The belt cap means a wall of 100 low-tier hives throttles itself, which quietly pushes the player toward merging. That is intended.

## Beekeeper and processor

The beekeeper stand is where honey becomes money, but not instantly: handed-in honey goes into a processor that converts a fixed amount per second, and upgrading the processor is the second money sink after bees.

- The beekeeper is an NPC at a stand on the plot, cycling idle animations (wave, stretch, look around, wipe brow) every 4 to 8 seconds. Walking onto the sell pad in front of the stand hands in all carried honey.
- The processor is a machine to the left of the stand with a hopper, a visible honey level, and a readout: "Queue: 1.2M honey — 625/s".
- Level L converts 2.5^(L-1) honey per second into $1 per honey (x prestige multiplier, x gamepass multiplier). Level 1 = 1/s, level 7 = 244/s, level 13 = 59,605/s.
- Upgrade cost from level L to L+1 = $100 x 3^(L-1): $100, $300, $900, $2,700, and so on. Bought by touching an Upgrade pad next to the machine.
- The queue has no cap. A visible backlog is the cue to upgrade.

Tuning note: processor throughput grows 2.5x per level but costs 3x, so each upgrade is slightly worse value than the last. The simulation shows players keep upgrading anyway because jar sizes grow 5x per tier; the drag is what stops money from being free in the late game.

## Prestige

Prestige is the long-term progression: each one multiplies all money earned by 1.5x permanently (stacking: P5 = 7.6x, P10 = 58x) and resets the run.

- Unlock: you must have created a bee of the required tier this run. Required tier = 5 + prestige number, capped at 12 (P1 needs Tier 6, P2 Tier 7, P7 and beyond Tier 12).
- Price: from a table, $10,000 for the first prestige, then $220K, $4.1M, $65M, $860M, $8.2B, $73B (P7) and on to $100T at P20; after P20 each prestige costs 1.65x the one before (full table in `src/shared/Config/Economy.lua`). The price pad shows both the requirement and the price; it activates only when both are met.
- Resets: money (back to $12), all hives, processor level (to 1), shop tier (to 1), bees-bought counter, jar counter.
- Keeps: prestige count and multiplier, gamepasses, lifetime stats.
- Flag: one flagpole beside the plot entrance with a flat-color flag reading "P3" (the number). Flag color steps every 5 prestiges: white, green, blue, purple, gold, then red for 25+.

**Pacing target (2026-11-04, replaces the first draft's):** P1 takes about 20 minutes and every prestige after takes about 10% longer than the one before: P2 22 min, P5 29, P10 47, P15 76, P20 about 2 hours, P30 about 5 hours (attentive player, no passes). Later prestiges must never get quicker.

Why it is a table: up to P7 each prestige also asks for a new tier, so the price climbs about 13x a step; from P8 the tier is capped at 12, income stops growing except through the x1.5 bonus, and the price only needs about 1.5 x 1.1 = 1.65x a step. One formula can't do both without bumps, so each price was solved in the simulator for its target time and rounded. The first draft's x10 per prestige made P8 take 52 min, P9 2 h and P10 never finish. To retune a single run, change its price; to change the whole slope, re-solve the table.

## Economy numbers

These values come from a simulation of a greedy player (buys the biggest pad it can afford, merges every 15 s, upgrades the processor when it pays back in under 10 min, walks the loop every 15 s; once the prestige tier is reached it stops buying bees and saves, still buying a processor level when that gets it there sooner). The first prestige lands at about 20 minutes, the target.

| Knob | Value |
|---|---|
| Starting money | $12 |
| Tier 1 bee price | $5 |
| Price multiplier per shop tier | x5 |
| Price growth per purchase (resets on shop tier change) | +1% |
| Shop tier | highest tier created − 4, min 1 |
| Jar interval, all tiers | 8 s |
| Honey per jar | 5^(tier − 1) |
| Money per honey | $1 x prestige multiplier |
| Processor rate at level L | 2.5^(L − 1) honey/s |
| Processor upgrade cost L → L+1 | $100 x 3^(L − 1) |
| Belt cap / travel time | 50 jars / 6 s |
| Prestige multiplier | x1.5 per prestige, stacking |
| Prestige price | table: $10K, $220K, $4.1M ... $100T (P20), then x1.65 each |
| Prestige requirement | Tier 5 + prestige number, max 12 |

First run (no multipliers), time to first create each tier:

| Tier | 2 | 3 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|
| Minutes | 1 | 2 | 9 | 25 | 37 | 51 | 51 | 53 | 64 | 119 |

> **2026-11-04:** the first-draft table above was wrong; the checked-in sim gives 0 / 3 / 5 / 11 / 19 / 30 / 38 / 57 / 70 / 86 / 89 for Tier 2 to 12 (Tier 4 included).

The simulation script lives in the repo as `tools/econ_sim.py`; rerun it after any change to a knob above. Every number here is a starting point: watch real players' time-to-first-prestige after launch and retune.

## Monetization

Cheap passes, many of them: the plan is to test what sells at the 19 to 79 Robux mark rather than one expensive pass. Launch with the first three; add the rest once the game has players.

| Gamepass | Robux | Effect | Launch |
|---|---|---|---|
| 2x Money | 19 | Doubles money from the processor, stacks with prestige | Yes |
| Auto Collect | 59 | Pickup pad honey goes straight to the processor queue | Yes |
| Lucky Jars | 49 | Jar variant odds x3 | Yes |
| Auto Merge | 29 | Presses E for you every 10 s | Later |
| 2x Bee Speed | 39 | Jar interval 8 s → 4 s | Later |
| Auto Buy | 79 | Buys the cheapest affordable bee every 5 s while you are off the pad | Later |

Dev products (repeatable): three cash packs priced 29, 79 and 199 Robux that pay 10, 30 and 100 shop-tier bees' worth of money at the player's current shop tier, so they stay useful at every stage. All passes are checked live with MarketplaceService on join and on purchase; nothing about ownership is stored in the save.

## Map and multiplayer

Six plots sit in a ring around a central hub, like Grow a Mutant, each joined to the hub by a short bridge.

- Server size 6, public. A joining player is assigned the first free plot; leaving frees it. Plots are claimed per session, not owned.
- Each plot is roughly 120 x 120 studs: the hive wall along the back edge with the conveyor behind it, pads in front (Buy 1 / 5 / 25 in a row, pickup pad at the belt end, Prestige pad), beekeeper stand and processor on the left, flagpole at the bridge end. Enough room that the zoomed-out wall view fits on a phone screen.
- Hub: spawn point, a sign board with the gamepass shop, a leaderboard for lifetime honey, and nothing else in v1.
- Players can walk onto other plots but cannot press their pads or E there; the prompt reads "Not your plot".
- Camera: no special camera in v1 beyond a wide view of the wall when standing on a Buy pad (returns on step-off). Merge and jars are readable from the default third-person camera.
- Low part count matters with six walls of up to 100 hives: a hive is one box MeshPart plus the bee model (under 20 parts); jars are single cylinders; the belt is a single moving surface.

## Data and saves

One profile per player, held with ProfileStore (session-locked so two servers can never write the same save at once), saved every 60 s and on leave. No offline earnings in v1.

```lua
Profile = {
  version = 1,
  money = 12,
  prestige = 0,
  hives = {1, 1, 3},          -- tiers in wall order, bottom-left first
  highestTier = 3,            -- this run
  shopBuys = 0,               -- purchases at the current shop tier
  processorLevel = 1,
  queuedHoney = 0,            -- honey waiting in the processor
  padHoney = 0,               -- honey waiting on the pickup pad
  stats = { lifetimeHoney = 0, lifetimeMoney = 0, jarsMade = 0, merges = 0, bestVariant = "" },
}
```

Jars in flight on the belt are not saved; on leave they are counted straight into padHoney. Gamepass ownership is never stored. Any field missing on load takes its default so later versions can add fields without a migration.

> **2026-11-05 (owner):** the game was built in one step (milestones 2–5 together) with a bare-bones HUD so it can be restyled later. Small additions the doc didn't spell out: you spawn on your own plot (the hub spawn is a fallback); Buy pads keep buying every 0.5 s while you stand on them; prestige also clears honey anywhere in the loop (pad, carried, queued, on the belt); the profile gained `carriedHoney` and `receipts`.

## Build plan

The game is built in Claude Code sessions against the repo, reusing the Rojo-based tool setup from mutant-farm, and ships in five milestones with the economy script checked in first.

1. Scaffold: copy the mutant-farm tooling (Rojo project, build/install scripts, CI), add `tools/econ_sim.py` from this doc, ProfileStore, a Config module holding every knob in the Economy table.
2. One plot, no multiplayer: wall, Buy pads, drop-in animation, merge with E, gravity rebuild. Playable with Tier 1 to 3 placeholder bees.
3. Honey: jars, variants, belt, cap, pickup pad, beekeeper, processor and its upgrade pad. First-run timing checked against the 25-minute target in Studio.
4. Six plots, bridges, hub, prestige with flag, gamepasses and dev products, bare-bones HUD (money, honey carried, prestige, shop tier) in flat colors.
5. The twelve bee models and the four jar variant looks, built in Lua; then a balance pass with real play sessions.

Handoff line for a new session: clone FarmBeesGetHoney, run `bash tools/install-tools.sh` (approve it when asked; it takes several minutes), and read this doc before touching code.
