# Farm Bees Get Honey — notes for Claude Code

Merge-and-conveyor idle game for Roblox. Luau, synced into Studio with Rojo. One PR per milestone (see `docs/DESIGN.md`, "Build plan").

**Design intent lives in `docs/DESIGN.md`; this file holds the live numbers and how the code does it.** Any rule change goes into DESIGN.md with a dated note *and* here, in the same commit.

## The one rule: the server is authoritative

- Clients send **intents only** (`src/shared/Remotes.lua`): currently `Merge()`. Never a price, amount, tier or timestamp. Pads (Buy 1/5/25, pickup, sell, upgrade, prestige) are step-on and detected by the server, so they have no remote.
- Every remote goes through `Net.on` (`src/server/Util/Net.lua`): rate limit (`Game.remoteCallsPerSecond`), loaded profile required; handlers validate every argument (`Util/Validate.lua`) and reject silently.
- The shared rule modules decide (`Economy`, `Merge`, `Wall`); the client only previews with them.

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
  Config/            Economy (every economy knob) Bees (the 12 tiers) Game (server, saving, timings)
                     Passes Products (ids 0 = not created in Creator Hub yet)
  Economy.lua        honeyPerJar, shopTier, beePrice, padCost, processorRate, upgradeCost,
                     prestigeTier/Price/Multiplier, canPrestige, moneyPerHoney, rollVariant
  Merge.lua          the merge rule: run(hives) -> { hives, merges, created, highest }, canMerge
  Wall.lua           10x10 slot layout (slot 1 bottom-left), free slots, room for a pad
  Format.lua Remotes.lua Types.lua Signal.lua
src/server/          ServerScriptService.Server
  Main.server.lua    Init() all, then Start() all, in order
  Services/          DataService (ProfileStore, snapshots)
  Util/              Net RateLimiter Validate
src/client/          StarterPlayerScripts.Client
  Main.client.lua    loads controllers the same way
  Controllers/       StateController (latest snapshot + Changed signal)
Packages/            vendored ProfileStore 1.0.3
tools/               econ_sim.py (economy simulator), check / test / harness (Lune), install-tools.sh
tests/               *.spec.luau
docs/DESIGN.md       the design doc     docs/HANDOFF.md   latest session handoff
```

## Profile data (ProfileStore, store `PlayerData_v1`)

Template in `DataService.lua`, exactly the design doc's profile: `version money prestige hives highestTier shopBuys processorLevel queuedHoney padHoney stats{lifetimeHoney lifetimeMoney jarsMade merges bestVariant}`. `hives` is a dense array of tiers in wall order (no holes). `profile:Reconcile()` fills missing fields on load, so new fields need no migration. Autosave every `Game.autoSaveSeconds` (60); ProfileStore flushes on leave and BindToClose. `DataService.onRelease(fn)` runs before the final save (milestone 3: count belt jars into `padHoney`). Pass ownership lives in `DataService.passes[player]` for the session only, never in the save. Studio without API access falls back to ProfileStore's mock store.

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
| Belt | cap 35 live jars, 6 s end to end |
| Processor | 2.5^(L − 1) honey/s at $1 per honey x prestige mult x pass mult; upgrade L→L+1 $100 x 3^(L − 1) |
| Prestige | needs Tier min(12, 5 + n) where n = the prestige being bought (P1 = Tier 6); price $10K x 10^(n − 1); x1.5 per prestige, stacking |

Sim (`python3 tools/econ_sim.py`, 2026-11-04, greedy bot as described in the doc; deterministic expected-value jars, `--random` agrees within a minute): P1 19.9 min, P2–P7 19–21 min each, **P8 52 min, P9 121 min, P10 not within 6 h**. First run without prestige (`--tiers`), minutes to first create Tier 2..12: 0 / 3 / 5 / 11 / 19 / 30 / 38 / 57 / 70 / 86 / 89. Both differ from the design doc's figures: open decision in `docs/HANDOFF.md`.

## Commands

Tools: lune 0.11.1, rojo 7.7.1, stylua 2.6.0, selene 0.31.0, installed by `bash tools/install-tools.sh` (cargo, pinned; several minutes). Python 3 standard library for the sim.

```
lune run tools/check                      # every .lua/.luau compiles
lune run tools/test                       # tests/*.spec.luau
python3 tools/econ_sim.py                 # prestige run lengths (--tiers, --prestiges N, --random --seed S, --money2x, --hours H)
stylua src tools tests                    # format
selene src                                # lint (needs `selene generate-roblox-std` once, with internet)
rojo build default.project.json -o build/FarmBeesGetHoney.rbxl
```

CI (`.github/workflows/ci.yml`) runs check, test, stylua --check, selene, the sim and a rojo build on every push and PR.

## Status by milestone

- **M1 Scaffold (2026-11-04): done.** Rojo project, install script, CI, Lune test harness, `tools/econ_sim.py`, ProfileStore + DataService, Config holding every knob, shared Economy / Merge / Wall with tests. Nothing in the world yet; not playtested in Studio (there is nothing to see).
- M2 One plot · M3 Honey · M4 Six plots, prestige, passes, HUD · M5 Bee models + jar looks: not started.
