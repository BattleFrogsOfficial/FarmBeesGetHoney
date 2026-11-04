# Handoff — 2026-11-04, Milestone 1 (Scaffold)

## What changed

- Repo created from the mutant-farm tooling: `default.project.json` (Rojo), `tools/install-tools.sh` (lune / rojo / stylua / selene, pinned), `tools/harness.luau` + `tools/test.luau` + `tools/check.luau`, `selene.toml`, `stylua.toml`, vendored ProfileStore 1.0.3, and a GitHub Actions CI workflow.
- `src/shared/Config/Economy.lua` holds every knob from the design doc's Economy table; `Bees`, `Game`, `Passes`, `Products` alongside.
- Pure shared modules with tests: `Economy` (prices, processor, prestige, variant roll), `Merge` (the doc's algorithm), `Wall` (10x10 layout).
- `DataService` with the doc's profile template, ProfileStore session lock, 60 s autosave, snapshot pushes; `Net` / `RateLimiter` / `Validate`; client `StateController`.
- `tools/econ_sim.py`: the greedy-player simulator described in the doc.

## Not tested

- Nothing has run in Studio yet. The world is empty until M2, so the only thing to check is that the place loads, a profile is created and a `State` snapshot reaches the client.
- The CI workflow has not run on GitHub yet (it is new in this push).

## Open decisions (owner)

1. **The sim doesn't reproduce the doc's run lengths.** With the doc's knobs and bot (biggest affordable pad, merge every 15 s, processor upgrade when it pays back in < 10 min, loop walked every 15 s, then saves for the prestige price once the tier is reached):
   - P1 19.9 min (doc: 25), P2–P7 19–21 min (doc: 17–23).
   - **P8 52 min, P9 121 min, P10 not reached in 6 h** (doc: shortening toward 5–8 min). Past P7 the tier requirement stops rising (capped at 12) and income stops growing, while the price keeps rising x10 per prestige against a x1.5 multiplier. Late runs get longer, not shorter.
   - First run to Tier 2..12: 0 / 3 / 5 / 11 / 19 / 30 / 38 / 57 / 70 / 86 / 89 min (doc: 1 / 2 / – / 9 / 25 / 37 / 51 / 51 / 53 / 64 / 119).
   Options: (a) accept and retune later from real players; (b) lower `prestigePriceMult` (e.g. x5) or let it apply only up to P7; (c) slow early tiers to get P1 back to 25 min (e.g. raise `beeBasePrice` or `priceGrowth`). Knobs are unchanged until you pick one.
2. The bot's choices are my reading of the doc: it saves money for a worthwhile processor upgrade rather than buying bees with it, and stops buying once the prestige tier is reached. Without saving it never upgrades and P1 takes ~4 h.

## Next (M2: one plot, no multiplayer)

Plot builder (wall, Buy 1/5/25 pads in a row), a `PlotService` that detects pad steps server-side and spends through one money writer, hive drop-in tween, E prompt + `Merge` intent with the column-fall rebuild under `Game.mergeAnimationMax`, placeholder Tier 1–3 bees. Add a headless server harness for the services (mutant-farm's `tools/server-harness.luau` is the model).
