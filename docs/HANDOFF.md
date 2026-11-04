# Handoff — 2026-11-04, Milestone 1 (Scaffold) + pacing follow-up

## What changed

- Scaffold from the mutant-farm tooling: Rojo project, `tools/install-tools.sh` (cargo, cloud) and `rokit.toml` (owner's computer), Lune check/test, stylua/selene config, CI, vendored ProfileStore.
- `Config/Economy.lua` holds every knob; shared `Economy` / `Merge` / `Wall` with tests; `DataService` on ProfileStore; `tools/econ_sim.py`.
- **Prestige pacing (owner, 2026-11-04):** P1 ≈ 20 min, each prestige ≈ 10% longer. The first draft's x10 price made P8+ explode (P10 never finished), so the price is now a table solved in the sim for P1–P20 ($10K ... $100T), then x1.65 each. Sim: 19.9 / 22.0 / 24.2 / 26.6 / 29.2 / 32.1 / 35.5 ... 47 (P10) ... 118 (P20) ... 301 (P30) min.
- Sim bot: while saving for the prestige it still buys a processor level when that reaches the price sooner (before, it froze its processor, which understated late income).
- Belt cap 35 → 50 jars per plot (owner).
- Lint fix in `Util/Net.lua` (the placeholder data getter now takes the player argument).

## Not tested

- Nothing has run in Studio (no world until M2).
- `rokit install` couldn't be tried in the cloud sandbox (GitHub downloads are blocked there); the CI job `rokit-build` exercises it.

## Settled (owner)

- Sim P1 at ~20 min is fine. The bot saving for processor upgrades is the intended behaviour. Late prestiges get slightly longer, never quicker.

## Next (M2: one plot, no multiplayer)

Plot builder (wall, Buy 1/5/25 pads in a row), a `PlotService` that detects pad steps server-side and spends through one money writer, hive drop-in tween, E prompt + `Merge` intent with the column-fall rebuild under `Game.mergeAnimationMax`, placeholder Tier 1–3 bees. Add a headless server harness for the services (mutant-farm's `tools/server-harness.luau` is the model). Work on a branch with a PR per milestone; merge to `main` so the owner's Desktop clone gets it with `git pull`.
