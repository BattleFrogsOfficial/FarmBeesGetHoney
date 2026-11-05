# Farm Bees Get Honey — notes for Claude Code

Merge-and-conveyor idle game for Roblox. Luau, synced into Studio with Rojo. One PR per milestone (see `docs/DESIGN.md`, "Build plan").

**Design intent lives in `docs/DESIGN.md`; this file holds the live numbers and how the code does it.** Any rule change goes into DESIGN.md with a dated note *and* here, in the same commit.

## The one rule: the server is authoritative

- Clients send **intents only** (`src/shared/Remotes.lua`): only `Merge()` (the E prompt, which the client creates on your own wall). Never a price, amount, tier or timestamp. Pads (Buy 1/5/25, pickup, sell, upgrade, prestige) are step-on and detected by the server, so they have no remote.
- Every remote goes through `Net.on` (`src/server/Util/Net.lua`): rate limit (`Game.remoteCallsPerSecond`), loaded profile required; handlers validate every argument (`Util/Validate.lua`) and reject silently.
- The shared rule modules decide (`Economy`, `Merge`, `Wall`, `Shop`, `Belt`, `Processor`, `Prestige`, `Perks`); services only wire them to the world. The client only previews.
- **HUD/UI is bare-bones on purpose** (owner, 2026-11-05): plain frames and text built in `src/client/UI.lua` + the controllers, every size/color/position in `Config/Hud.lua`. World signs are SurfaceGuis built in `Util/World.lua`, colors in `Config/Visuals.lua`. Keep them easy to restyle; don't add polish yet.

## Conventions

- **Config, not logic:** every balance number lives in `src/shared/Config/*.lua`. `Config/Economy.lua` is the design doc's Economy table; `tools/econ_sim.py` holds a copy of the same knobs and `tests/config.spec.luau` fails if they drift. Change both, then rerun the sim.
- Pure logic goes in `src/shared` with a `tests/*.spec.luau`.
- v1 UI is bare-bones: flat solid-color frames and plain text, no icons. Visual effort goes into the 12 bee models and the jars only.
- Services/controllers are plain tables with `Init()` (no yielding, no cross-service calls) and `Start()` (may yield, may use other services). Add new ones to the `order` list in `Main.*.lua`.
- Files and modules `PascalCase.lua`; services end in `Service`, client modules in `Controller`. Functions and locals `camelCase`, constants `UPPER_SNAKE`. Remotes: verbs client→server, nouns server→client.
- Ids: bees `Honey Bumble Carpenter Mason Sweat Leafcutter Mining Orchid Cuckoo Giant Royal Queen`; variants `Shiny Golden Rainbow Quantum`; passes `Money2x AutoCollect LuckyJars AutoMerge BeeSpeed2x AutoBuy`; products `CashSmall CashMedium CashLarge`.
- No model names in commits or code. Commit messages end with the attribution lines the session asks for.

## Layout

```
src/shared/          ReplicatedStorage.Shared — pure modules, usable on both sides and in Lune
  Config/            Economy (every economy knob) Bees (the 12 tiers) BeeStyle (each tier's look)
                     Game (server, saving, timings) Layout (map + plot geometry) Visuals (world colors)
                     Hud (HUD sizes/colors) Passes Products (ids 0 = not created in Creator Hub yet)
  Economy.lua        honeyPerJar, shopTier, beePrice, padCost, processorRate, upgradeCost,
                     prestigeTier/Price/Multiplier, canPrestige, moneyPerHoney, rollVariant
  Merge.lua          run(hives), canMerge, plan(hives) -> result, moves (kept/new per slot), consumed
  Shop.lua           quote/buy (Buy pads), noteTier (highest tier + shop-tier reset), cashPack
  Belt.lua           due(timers, now, free): which hives drop a jar (cap holds the rest), stagger
  Processor.lua      step (queue -> money), upgrade, handIn
  Prestige.lua       status, apply (the reset), flagIndex
  Perks.lua          pass effects: moneyPerHoney, luck, jarInterval
  Wall.lua           10x10 slot layout (slot 1 bottom-left), free slots, room for a pad
  BeeModel.lua       builds any tier's bee from parts (Config/BeeStyle), < 20 parts, welds to a hive
  HiveModel.lua      five-sided hive box, open front toward the belt (tier color, number) + its bee inside
  JarModel.lua       jar (physics cylinder + lid, tag/gem by tier band, variant tint + particles)
  Format.lua Remotes.lua Types.lua Signal.lua
src/server/          ServerScriptService.Server
  Main.server.lua    Init() all, then Start() all, in order
  Services/          DataService (ProfileStore, snapshots, saveNow) PlotService (map, plot claim, spawn,
                     step-on pads, pad signs, flag) HiveService (Buy pads, merge + animation, Auto Merge,
                     Auto Buy, jar timers) HoneyService (jars, belt, pickup pad, Auto Collect)
                     ProcessorService (hand in, processing, upgrade pad, readout) PrestigeService
                     MonetizationService (passes, cash packs) LeaderboardService (leaderstats, hub board)
  Util/              World (builds hub, 6 plots, bridges, walls, belts, pads, stand, processor, flags)
                     Net RateLimiter Validate
src/client/          StarterPlayerScripts.Client
  Main.client.lua    loads controllers the same way
  UI.lua             frame / text / button helpers (styling from Config/Hud)
  Controllers/       StateController (snapshot) HudController (stats, toast, SHOP button)
                     ShopController (pass + cash pack panel, hub board prompt)
                     PlotController (E merge prompt, wall camera on Buy pads, beekeeper idles)
Packages/            vendored ProfileStore 1.0.3
rokit.toml           tool versions for the owner's computer
tools/               econ_sim.py, check / test / harness / smoke (Lune), install-tools.sh
  preview/           export.luau + render.mjs: screenshots of the real World / bee / jar code
tests/               *.spec.luau
docs/DESIGN.md       the design doc     docs/HANDOFF.md   latest session handoff
```

## How the game runs (server)

- **Map** (`World.build`, from `PlotService.Init`): the hub (spawn, pass-shop board, top-honey board) at the origin, 6 plots on a ring of radius 150 joined by bridges. Each plot is 120 x 120; plot-local +z points to the hub. A new Baseplate place's `Baseplate` / `SpawnLocation` are deleted first.
- **Plots** are claimed per session (first free), spawn puts you on yours facing the wall. Pads are step-on: `PlotService` checks every root part every 0.1 s; entering a pad calls its handler once; Buy pads repeat every `Game.buyRepeatSeconds` (0.5) while you stand there. Someone else's pad says "Not your plot".
- **Hives** (owner, 2026-11-05): no wall. A free-standing 10x10 stack of five-sided boxes (back, top, bottom, left, right) sits on a low platform at the back of the plot, open fronts facing the conveyor, each bee living inside its box. Belt A runs along the front of the stack; jars appear on it right in front of their column.
- **Buy** (`Shop.buy`): hive boxes drop in with a bounce + dust. **Merge** (`Merge.plan`): consumed hives fly to the merge point (0.4 s), flash, then every hive tweens to its new slot (0.55 s): about 1 s total, under `Game.mergeAnimationMax`. Buys, jars and prestige wait while it runs. A hive is an invisible anchored root (tweened) with its five panels and bee welded to it: 17–24 parts.
- **Jars** (`HoneyService`, every 0.1 s): each hive has a timer (`HiveService.timers`); due hives drop a jar onto belt A in front of their column unless 50 jars are live (`Belt.due`, longest-waiting first). The belt is two anchored parts with `AssemblyLinearVelocity` (14 studs/s): A along the front of the hive stack toward +x, B down the right side to the bin; a jar past `Layout.beltEndZ`, fallen off, or 30 s old is counted (pickup pad, or the queue with Auto Collect) and removed. Leaving counts the belt's jars into `padHoney`; prestige discards them.
- **Processor** (`ProcessorService`, every 0.25 s): `Processor.step` at the level's rate x `Perks.moneyPerHoney`. Sell pad hands in carried honey; Upgrade pad buys one level per step-on.
- **Prestige** pad: `Prestige.apply` resets money ($12), hives, highest tier, shop buys, processor level, and all honey in the loop (pad, carried, queued, belt); flag shows "P<n>", color every 5 (`Visuals.flagColors`).
- **Passes** (`MonetizationService`): checked with `UserOwnsGamePassAsync` on join (skipped in Studio unless `Game.studioPasses`) and on `PromptGamePassPurchaseFinished`; ownership in `DataService.passes` only. **Cash packs**: `ProcessReceipt` grants `Shop.cashPack` once per PurchaseId (`profile.receipts`, last 50) and saves before answering PurchaseGranted. Ids of 0 are skipped (Studio prints which).
- **Leaderboard**: `leaderstats` Prestige + Honey (lifetime); the hub board reads OrderedDataStore `LifetimeHoney_v1` every 120 s (says it needs API access when it can't).

## Profile data (ProfileStore, store `PlayerData_v1`)

Template in `DataService.lua`: the design doc's profile `version money prestige hives highestTier shopBuys processorLevel queuedHoney padHoney stats{lifetimeHoney lifetimeMoney jarsMade merges bestVariant}` plus `carriedHoney` (picked up, not handed in) and `receipts` (granted PurchaseIds), both added 2026-11-05. `hives` is a dense array of tiers in wall order (no holes). `profile:Reconcile()` fills missing fields on load, so new fields need no migration. Autosave every `Game.autoSaveSeconds` (60); ProfileStore flushes on leave and BindToClose. `DataService.onRelease(fn)` runs before the final save with the profile and passes still readable (HoneyService counts belt jars into `padHoney` there). Pass ownership lives in `DataService.passes[player]` for the session only, never in the save. Studio without API access falls back to ProfileStore's mock store.

## Economy (source of truth: `src/shared/Config/Economy.lua`)

| Knob | Value |
|---|---|
| Starting money | $12 |
| Bee price | $5 x 5^(shop tier − 1) x 1.01^(buys at this shop tier); buys reset when the shop tier rises |
| Shop tier | highest tier created this run − 4, min 1 |
| Pads | Buy 1 / 5 / 25, each the sum of the next N prices (money kept unrounded; display rounds) |
| Merge | 3 → 1, cascades up, Tier 12 never merges, wall rebuilt ascending |
| Wall | 10 x 10 = 100 slots, fill bottom row left→right then up |
| Jars | every 8 s per hive, honey 5^(tier − 1) x variant |
| Variants | Shiny 2% x2, Golden 0.5% x5, Rainbow 0.05% x20, Quantum 0.005% x100; one per jar, rarest checked first; Lucky Jars x3 odds |
| Belt | cap 50 live jars per plot, 6 s end to end |
| Processor | 2.5^(L − 1) honey/s at $1 per honey x prestige mult x pass mult; upgrade L→L+1 $100 x 3^(L − 1) |
| Prestige | needs Tier min(12, 5 + n) where n = the prestige being bought (P1 = Tier 6); price from `prestigePrices` (P1–P20: $10K, $220K, $4.1M, $65M, $860M, $8.2B, $73B, $170B, $330B, $640B, $1T, $1.7T, $3.1T, $5T, $8.5T, $14T, $24T, $39T, $63T, $100T), then x`prestigePriceTail` 1.65 each; x1.5 per prestige, stacking |

**Pacing target: P1 ≈ 20 min, each prestige ≈ 10% longer than the one before.** The price table is solved for it in the sim; to retune one run change its price, to change the slope re-solve the table (bisect each price for its target time, round to 2 significant figures).

Sim (`python3 tools/econ_sim.py --prestiges 30`, 2026-11-04, deterministic expected-value jars): 19.9 / 22.0 / 24.2 / 26.6 / 29.2 / 32.1 / 35.5 (P7) / 38.5 / 42.8 / 47.4 (P10) ... 75.6 (P15) ... 118 (P20) ... 301 (P30) min; every step x1.06–1.14, x1.10 from P21 on. `--random` adds a few minutes of noise per run (lucky variant jars), same trend. `--money2x` halves every run (P1 10 min, P20 60 min). First run without prestige (`--tiers`), minutes to first create Tier 2..12: 0 / 3 / 5 / 11 / 19 / 30 / 38 / 57 / 70 / 86 / 89. The bot plays perfectly; real players are likely ~1.3–1.6x slower.

## Commands

Tools: lune 0.11.1, rojo 7.7.1, stylua 2.6.0, selene 0.31.0, pinned twice: `rokit.toml` (the owner's computer: `rokit install`) and `tools/install-tools.sh` (cloud sessions, cargo; several minutes). Keep the two in sync. Python 3 standard library for the sim.

```
lune run tools/check                      # every .lua/.luau compiles
lune run tools/test                       # tests/*.spec.luau
python3 tools/econ_sim.py                 # prestige run lengths (--tiers, --prestiges N, --random --seed S, --money2x, --hours H)
stylua src tools tests                    # format
selene src                                # lint (needs `selene generate-roblox-std` once, with internet)
rojo build default.project.json -o build/FarmBeesGetHoney.rbxl
lune run tools/smoke -- build/FarmBeesGetHoney.rbxl          # builds the world + every hive/bee/jar: part budgets, bees fit slots, pads, belt
lune run tools/preview/export -- build/FarmBeesGetHoney.rbxl build/scene.json && node tools/preview/render.mjs build/scene.json build/shots
(cd tools/preview && npm install)         # once, for the renderer (three.js); Chromium + Playwright are preinstalled in cloud sessions
```

Preview cameras: `SHOTS='[["name",[eye],[target],fov]]'`. Plot 1 is centered at (150, 0, 0) with its hive stack toward +x, e.g. `["front",[128,14,0],[199,10,0],60]` (what a player on the pads sees). The renderer draws SurfaceGui text over the whole face (the hive numbers are really small corner labels).

CI (`.github/workflows/ci.yml`): job `check` (cargo tools) runs check, test, stylua --check, selene, the sim, a rojo build and the world smoke test; job `rokit-build` installs from `rokit.toml`, runs the tests and uploads the built place as the `FarmBeesGetHoney-place` artifact. The owner works from a clone on their Desktop (`git pull`, `rojo serve`): push finished work to `main` (or merge its PR) so a pull picks it up.

## Status by milestone

- **M1 Scaffold (2026-11-04): done.** Follow-up the same day: prestige price table (+10% per run), belt cap 50, `rokit.toml`, lint fix.
- **M2–M5 (2026-11-05): built in one pass, not yet played in Studio.** One plot per player on a 6-plot map with hub and bridges; hive wall with Buy 1/5/25, drop-in, E merge with the fly-in/rebuild animation; jars with variants on a moving belt with the 50 cap; pickup pad, beekeeper (idle animations), processor + upgrade pad; prestige with flag; all six passes and three cash packs (ids still 0); leaderstats + top-honey board; bare-bones HUD and shop panel; the 12 bee models and the jar tier/variant looks. Checked headlessly (tests, smoke test, preview renders); the Studio list is in docs/HANDOFF.md.
