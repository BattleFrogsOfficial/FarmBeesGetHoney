#!/usr/bin/env bash
# Cloud sessions / CI: installs the command-line tools this repo needs (pinned to the versions it was built and checked
# with) from crates.io via cargo. Safe to re-run: cargo skips tools already at the right version. Use it as (or from) a cloud environment setup script.
#   lune 0.11.1   tests and the compile check
#   rojo 7.7.1    builds the place file
#   stylua 2.6.0  formatting
#   selene 0.31.0 linting (needs `selene generate-roblox-std` once, with internet)
# On your own computer use Rokit instead (rokit.toml, same versions): rokit install
set -euo pipefail

if ! command -v cargo >/dev/null 2>&1; then
	curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
	. "$HOME/.cargo/env"
fi
export PATH="$HOME/.cargo/bin:$PATH"

# Skips a tool already at its pinned version (e.g. restored from a CI cache); --force replaces
# any other version.
need() { # <binary> <version>
	! command -v "$1" >/dev/null 2>&1 || ! "$1" --version 2>/dev/null | grep -q "$2"
}
need lune 0.11.1 && cargo install --locked --force lune --version 0.11.1
need rojo 7.7.1 && cargo install --locked --force rojo --version 7.7.1
need stylua 2.6.0 && cargo install --locked --force stylua --version 2.6.0 --features luau # without the feature it cannot parse Luau
need selene 0.31.0 && cargo install --locked --force selene --version 0.31.0

lune --version && rojo --version && stylua --version && selene --version
python3 --version # tools/econ_sim.py (standard library only)
