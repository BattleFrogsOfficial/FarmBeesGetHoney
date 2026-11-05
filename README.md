# Farm Bees Get Honey

A Roblox merge-and-conveyor idle game: buy bees, merge three of a tier into the next (12 tiers, Honey Bee to Queen Bee), and their honey jars ride a conveyor to a beekeeper whose processor turns honey into money. Prestige for a permanent, stacking 1.5x money bonus.

Design: [`docs/DESIGN.md`](docs/DESIGN.md). Notes for Claude Code sessions: [`CLAUDE.md`](CLAUDE.md).

## Set up on your computer (once)

You need **Git**, **Rokit**, **Roblox Studio** and the **Rojo Studio plugin**.

1. Install Git: https://git-scm.com/downloads
2. Install Rokit (it installs Rojo and the other tools at the exact versions this repo uses):
   - Windows (PowerShell): `Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression`
   - Mac: `curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash`

   Then close and reopen the terminal.
3. Put the project on your Desktop:
   - Windows: `cd $HOME\Desktop` then `git clone https://github.com/BattleFrogsOfficial/FarmBeesGetHoney.git`
   - Mac: `cd ~/Desktop` then `git clone https://github.com/BattleFrogsOfficial/FarmBeesGetHoney.git`
4. Install the tools: `cd FarmBeesGetHoney` then `rokit install` (say yes to each tool).
5. Install the Rojo Studio plugin: `rojo plugin install` (or from the Roblox Creator Store: "Rojo").

## Every time

1. Get the latest: in the `FarmBeesGetHoney` folder run `git pull`, then `rokit install` (only does something if a tool version changed).
2. Start syncing: `rojo serve`
3. Open Studio on a new **Baseplate** place, open the Rojo plugin and click **Connect**. The scripts appear in ReplicatedStorage, ServerScriptService and StarterPlayerScripts.
4. Press **Play**. You spawn on your own plot facing the hive wall. Step on **BUY 1** (blue pad), press **E** at the wall to merge three of a kind, pick up honey on the yellow pad at the end of the conveyor, hand it in at the orange pad by the beekeeper, upgrade the processor on the green pad, and prestige on the purple pad.

To get a place file instead of live sync: `rojo build -o FarmBeesGetHoney.rbxl` and open it in Studio. CI also builds one on every push (GitHub → Actions → the latest run → Artifacts → FarmBeesGetHoney-place).

Saved data in Studio uses a mock store unless the place is published and **Game Settings → Security → Enable Studio Access to API Services** is on. Once published: **Places → Max Players: 6** (one plot per player).

## Developer tools

`lune run tools/test` (tests), `lune run tools/check` (compile check), `python3 tools/econ_sim.py` (economy simulator; needs Python 3). See CLAUDE.md for the full list. Cloud sessions install the same tools with `bash tools/install-tools.sh`.

ProfileStore is vendored in `Packages/` (no Wally step).
