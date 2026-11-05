# Handoff — 2026-11-05, the whole game (M2–M5) in one pass

**Follow-up (owner):** no wall. Hives are open-front five-sided boxes stacked on a platform behind the conveyor, bees inside; jars appear on the belt in front of each column. Belt A's rails are 1.5 studs high so the bottom row shows.

## What changed

Everything after the scaffold, built together at the owner's request with a bare-bones HUD:

- **Map** (`Util/World.lua`, geometry in `Config/Layout`, colors in `Config/Visuals`): hub with spawn, pass-shop board and top-honey board; 6 plots in a ring, bridges, rails. Each plot: 10x10 hive wall, two-segment conveyor with rails and a bin, Buy 1/5/25, pickup, sell, upgrade and prestige pads with signs, beekeeper stand + NPC, processor with a honey level and readout, flagpole, owner sign.
- **Server services**: PlotService (claim, spawn on your plot, pad detection, pad signs, flag), HiveService (buy, merge + animation, Auto Merge, Auto Buy, jar timers), HoneyService (jars, cap, belt end, pickup, Auto Collect, leave/prestige handling), ProcessorService, PrestigeService, MonetizationService, LeaderboardService.
- **Shared rules with tests**: Shop, Belt, Processor, Prestige, Perks, Merge.plan (39 tests).
- **Looks**: `BeeModel` (12 tiers from `Config/BeeStyle`, 12–19 parts each), `HiveModel` (tier-colored box, Neon at 12), `JarModel` (4 tier bands, 4 variants with tint + particles).
- **Client**: bare-bones HUD (stats panel, toast, SHOP button) and shop panel, E merge prompt on your wall, wide wall camera on Buy pads, beekeeper idle animations. All styling in `Config/Hud`.
- **Tools**: `tools/smoke.luau` (world + models headless, in CI) and `tools/preview` (screenshots).

## Not tested (Studio list)

Nothing has been played in Studio. Check, in order:

1. Play solo: you spawn on a plot facing the wall; the map has 6 plots and a hub; no errors in Output.
2. Buy 1 with the starting $12: a box drops into the bottom-left slot. Stand on Buy 1: it keeps buying every 0.5 s while affordable.
3. Buy 3, press E at the wall: they fly together and a Tier 2 drops in (well under 1.5 s).
4. Jars: appear on the belt in front of each hive column every 8 s, ride belt A then down belt B, vanish at the end; the pickup sign counts up. **Watch the corner** where belt A meets B: if jars tip or pile up, lower `Layout.beltSpeed` or widen the rails.
5. Pickup pad -> HUD "Honey carried"; sell pad -> processor queue readout and honey level; money rises at 1/s; Upgrade pad.
6. Wide camera on a Buy pad, back to normal off it.
7. Prestige (fastest test: temporarily lower `prestigePrices[1]` and set a Tier 6 hive in Studio's command bar, or play ~20 min): resets, flag shows P1.
8. Two players (Studio Test > 2 players): second plot, "Not your plot" on the other's pads and wall.
9. Leave and rejoin (needs API access): money, wall, honey kept; belt jars counted into the pickup pad.

## Open decisions (owner)

- Create the passes and cash packs in Creator Hub and put their ids in `Config/Passes.lua` / `Config/Products.lua` (the shop says "Not on sale yet" until then).
- Sounds: none yet (the doc mentions a thud on drop).

## Next

Studio pass from the list above, then real play sessions for balance (the sim assumes a perfect player; real P1 likely 26–32 min).
