#!/usr/bin/env python3
"""Farm Bees Get Honey economy simulator.

A greedy bot plays the core loop second by second:
  - buys the biggest pad (25 / 5 / 1) it can afford and has wall room for,
  - merges every MERGE_EVERY seconds,
  - upgrades the processor when the upgrade pays back in under PAYBACK seconds,
  - walks the loop (pickup pad -> beekeeper) every WALK_EVERY seconds,
  - once the next prestige's tier is reached, stops buying bees and saves for the price, still buying a
    processor level whenever that gets it to the price sooner.

Every knob mirrors src/shared/Config/Economy.lua: change both together.

  python3 tools/econ_sim.py                 # prestige run report (P1..P20; target ~20 min, then +10% each)
  python3 tools/econ_sim.py --tiers         # first run without prestiging: minutes to each tier
  python3 tools/econ_sim.py --prestiges 15 --random --seed 3
"""

import argparse
import random

# ---- knobs (keep in sync with src/shared/Config/Economy.lua) ----
STARTING_MONEY = 12
BEE_BASE_PRICE = 5
SHOP_TIER_PRICE_MULT = 5
PRICE_GROWTH = 1.01
SHOP_TIER_OFFSET = 4
MAX_TIER = 12
MERGE_SIZE = 3
WALL_SLOTS = 100
JAR_INTERVAL = 8.0
HONEY_BASE = 5  # honey per jar = HONEY_BASE ** (tier - 1)
PROCESSOR_RATE_BASE = 2.5  # honey/s at level L = base ** (L - 1)
PROCESSOR_COST_BASE = 100
PROCESSOR_COST_MULT = 3
BELT_CAP = 50
BELT_SECONDS = 6.0
PRESTIGE_MULT = 1.5
PRESTIGE_PRICES = [
    10e3, 220e3, 4.1e6, 65e6, 860e6, 8.2e9, 73e9,
    170e9, 330e9, 640e9, 1.0e12, 1.7e12, 3.1e12, 5.0e12,
    8.5e12, 14e12, 24e12, 39e12, 63e12, 100e12,
]
PRESTIGE_PRICE_TAIL = 1.65
PRESTIGE_TIER_BASE = 5
# variant: (chance, multiplier)
VARIANTS = [(0.02, 2), (0.005, 5), (0.0005, 20), (0.00005, 100)]

# ---- bot behaviour ----
MERGE_EVERY = 15
WALK_EVERY = 15
PAYBACK = 600
PADS = (25, 5, 1)


def honey_per_jar(tier):
    return HONEY_BASE ** (tier - 1)


def shop_tier(highest):
    return max(1, highest - SHOP_TIER_OFFSET)


def bee_price(st, buys):
    return BEE_BASE_PRICE * SHOP_TIER_PRICE_MULT ** (st - 1) * PRICE_GROWTH ** buys


def pad_cost(st, buys, n):
    return sum(bee_price(st, buys + i) for i in range(n))


def processor_rate(level):
    return PROCESSOR_RATE_BASE ** (level - 1)


def upgrade_cost(level):
    return PROCESSOR_COST_BASE * PROCESSOR_COST_MULT ** (level - 1)


def prestige_tier(prestige):
    return min(MAX_TIER, PRESTIGE_TIER_BASE + prestige + 1)


def prestige_price(prestige):
    n = prestige + 1
    if n <= len(PRESTIGE_PRICES):
        return PRESTIGE_PRICES[n - 1]
    return PRESTIGE_PRICES[-1] * PRESTIGE_PRICE_TAIL ** (n - len(PRESTIGE_PRICES))


def expected_variant_mult(luck=1.0):
    p_none = 1 - sum(c * luck for c, _ in VARIANTS)
    return p_none + sum(c * luck * m for c, m in VARIANTS)


def merge(counts):
    """counts: list indexed 1..MAX_TIER. Returns (new counts, merges done)."""
    counts = counts[:]
    merges = 0
    for t in range(1, MAX_TIER):
        up = counts[t] // MERGE_SIZE
        counts[t + 1] += up
        counts[t] -= up * MERGE_SIZE
        merges += up
    return counts, merges


class Run:
    def __init__(self, prestige, rng, money_mult_extra=1.0):
        self.prestige = prestige
        self.mult = PRESTIGE_MULT ** prestige * money_mult_extra
        self.rng = rng
        self.money = STARTING_MONEY
        self.counts = [0] * (MAX_TIER + 1)
        self.highest = 0
        self.buys = 0
        self.level = 1
        self.queue = 0.0
        self.pad = 0.0
        self.jar_clock = 0.0  # fractional jars carried between ticks
        self.first_tier = {}

    def hives(self):
        return sum(self.counts)

    def supply_rate(self):
        """Honey per second reaching the pickup pad, after the belt cap."""
        jars = self.hives() / JAR_INTERVAL
        if jars == 0:
            return 0.0
        honey = sum(self.counts[t] * honey_per_jar(t) for t in range(1, MAX_TIER + 1)) / JAR_INTERVAL
        cap = BELT_CAP / BELT_SECONDS
        scale = min(1.0, cap / jars)
        return honey * scale * expected_variant_mult()

    def produce(self, dt):
        if self.rng is None:
            self.pad += self.supply_rate() * dt
            return
        jars = self.hives() / JAR_INTERVAL
        cap = BELT_CAP / BELT_SECONDS
        n = min(jars, cap) * dt + self.jar_clock
        whole = int(n)
        self.jar_clock = n - whole
        if whole == 0:
            return
        weights = [self.counts[t] for t in range(1, MAX_TIER + 1)]
        tiers = self.rng.choices(range(1, MAX_TIER + 1), weights=weights, k=whole)
        for t in tiers:
            m = 1
            r = self.rng.random()
            acc = 0.0
            for c, vm in reversed(VARIANTS):  # rarest first, one variant max
                acc += c
                if r < acc:
                    m = vm
                    break
            self.pad += honey_per_jar(t) * m

    def note_tier(self, t, now):
        if t > self.highest:
            old_st = shop_tier(self.highest)
            self.highest = t
            if shop_tier(t) != old_st:
                self.buys = 0
        for k in range(2, t + 1):
            self.first_tier.setdefault(k, now)

    def do_merge(self, now):
        self.counts, _ = merge(self.counts)
        top = max((t for t in range(1, MAX_TIER + 1) if self.counts[t]), default=0)
        self.note_tier(top, now)

    def upgrade_worth_it(self):
        cost = upgrade_cost(self.level)
        supply = self.supply_rate()
        gain = (min(supply, processor_rate(self.level + 1)) - min(supply, processor_rate(self.level))) * self.mult
        # A backlog in the queue also counts: it is honey the old level can't keep up with.
        if self.queue > 0:
            gain = max(gain, (processor_rate(self.level + 1) - processor_rate(self.level)) * self.mult * min(1.0, self.queue / (processor_rate(self.level + 1) * PAYBACK)))
        return gain > 0 and cost / gain <= PAYBACK

    def try_upgrade(self):
        """True while the processor is the next purchase (bought now, or being saved for)."""
        if not self.upgrade_worth_it():
            return False
        cost = upgrade_cost(self.level)
        if self.money < cost:
            return True
        self.money -= cost
        self.level += 1
        return True

    def income(self, level):
        return min(self.supply_rate(), processor_rate(level)) * self.mult

    def upgrade_while_saving(self, price):
        """Saving for the prestige: buy a processor level when it gets there sooner."""
        cost = upgrade_cost(self.level)
        if self.money < cost:
            return
        now, after = self.income(self.level), self.income(self.level + 1)
        if now <= 0 or after <= now:
            return
        left = price - self.money
        if (left + cost) / after < left / now:
            self.money -= cost
            self.level += 1

    def try_buy(self):
        free = WALL_SLOTS - self.hives()
        st = shop_tier(self.highest)
        for n in PADS:
            if n <= free and pad_cost(st, self.buys, n) <= self.money:
                self.money -= pad_cost(st, self.buys, n)
                self.buys += n
                self.counts[st] += n
                if self.highest < st:
                    self.highest = st
                return True
        return False

    def play(self, limit_seconds, stop_at_prestige=True):
        """Returns seconds to prestige (or None if not reached)."""
        need = prestige_tier(self.prestige)
        price = prestige_price(self.prestige)
        t = 0
        while t < limit_seconds:
            t += 1
            self.produce(1)
            if t % WALK_EVERY == 0:
                self.queue += self.pad
                self.pad = 0
            done = min(self.queue, processor_rate(self.level))
            self.queue -= done
            self.money += done * self.mult
            if t % MERGE_EVERY == 0:
                self.do_merge(t)
            saving = stop_at_prestige and self.highest >= need
            if saving:
                if self.money >= price:
                    return t
                self.upgrade_while_saving(price)
                continue
            if not self.try_upgrade():
                # One pad press per second; if the wall is full, merge now.
                if not self.try_buy() and self.hives() >= WALL_SLOTS - PADS[-1] + 1:
                    self.do_merge(t)
        return None


def fmt_min(s):
    return "-" if s is None else f"{s / 60:.0f}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tiers", action="store_true", help="first run, no prestige: minutes to each tier")
    ap.add_argument("--prestiges", type=int, default=20)
    ap.add_argument("--hours", type=float, default=12, help="time limit per run")
    ap.add_argument("--random", action="store_true", help="roll jars and variants instead of expected values")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--money2x", action="store_true", help="owns the 2x Money pass")
    args = ap.parse_args()
    rng = random.Random(args.seed) if args.random else None
    extra = 2.0 if args.money2x else 1.0
    limit = int(args.hours * 3600)

    if args.tiers:
        run = Run(0, rng, extra)
        run.play(limit, stop_at_prestige=False)
        print("First run, no prestige: minutes to first create each tier")
        print("Tier    " + " ".join(f"{t:>4}" for t in range(2, MAX_TIER + 1)))
        print("Minutes " + " ".join(f"{fmt_min(run.first_tier.get(t)):>4}" for t in range(2, MAX_TIER + 1)))
        return

    print("Prestige  needs  price                 minutes  vs prev  processor  money mult")
    total = 0
    prev = None
    for p in range(args.prestiges):
        run = Run(p, rng, extra)
        s = run.play(limit)
        if s is None:
            print(f"P{p + 1:<8} T{prestige_tier(p):<5} ${prestige_price(p):<20,.0f} not reached in {args.hours} h")
            break
        total += s
        ratio = f"x{s / prev:.2f}" if prev else "-"
        prev = s
        print(f"P{p + 1:<8} T{prestige_tier(p):<5} ${prestige_price(p):<20,.0f} {s / 60:>7.1f}  {ratio:<7}  L{run.level:<9} x{run.mult:,.1f}")
    print(f"Total: {total / 60:.0f} min")


if __name__ == "__main__":
    main()
