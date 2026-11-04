# Farm Bees Get Honey

A Roblox merge-and-conveyor idle game: buy bees, merge three of a tier into the next (12 tiers, Honey Bee to Queen Bee), and their honey jars ride a conveyor to a beekeeper whose processor turns honey into money. Prestige for a permanent, stacking 1.5x money bonus.

Design: [`docs/DESIGN.md`](docs/DESIGN.md). Notes for Claude Code sessions: [`CLAUDE.md`](CLAUDE.md).

## Run it in Studio

You need **Roblox Studio** and **Rojo 7** (the command-line tool plus the Rojo Studio plugin).

1. From this folder: `rojo serve`
2. Open Studio on a new **Baseplate** place, open the Rojo plugin and click **Connect**.
3. Press **Play**.

Saved data in Studio uses a mock store unless the place is published and **Game Settings → Security → Enable Studio Access to API Services** is on.

Once published: **Places → Max Players: 6** (one plot per player).

## Developer tools

```bash
bash tools/install-tools.sh
```

Then `lune run tools/test`, `lune run tools/check` and `python3 tools/econ_sim.py`. See CLAUDE.md for the full list.

ProfileStore is vendored in `Packages/` (no Wally step).
