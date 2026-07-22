# Death's At The Door — Balance & Phase Plan

> Companion to DESIGN.md. **All numbers are starting points to playtest**, but
> they're chosen to be internally consistent so a first run lands in the target
> window instead of flailing. Change them in the `.tres` Resources, not in code.

---

## 1. The one identity that governs everything

The timer is both the clock and the resource. So for a run that lasts `T` seconds
of real play and ends in a Reprieve:

```
total_time_added_across_run  =  (win_threshold - start_time)  +  T
                             =  (3000 - 300)                  +  T
                             =  2700 + T
```

And per dialogue section, the **break-even reward = the cadence** (the seconds that
drain between sections). Add less than that and you're losing ground; add more and
you're climbing toward the Reprieve.

**Target:** a satisfying win at **~18–22 min**. With a **60 s cadence**, that's
**~18–22 sections**, and you must add **2700 + ~1200 ≈ 3900 s** total across them —
about **~195 s of *net* gain per section** on average (net = reward − 60 s drain).

That average is only reachable if the player wins **Medium/Hard** checks, not just
Safe. Which is the point: survival requires engaging with the dialogue + upgrade
loop, and pure stalling routes you to Last Call.

---

## 2. Dialogue tiers (drop into `DialogueOption` `.tres`)

Check math: `d20 + stat ≥ difficulty`. Success chance `= clamp((21 − (DC − stat))/20, 0.05, 0.95)`.

| Tier | `stat` | `difficulty` (DC) | `time_reward` | `regret_delta` | P @stat 1 | P @stat 5 | P @stat 8 |
|---|---|---|---|---|---|---|---|
| **Safe** | `""` | — (auto) | **+15** | 0 | 100% | 100% | 100% |
| **Easy** | `charisma` | **8** | **+60** | 0 | 70% | 90% | 95% |
| **Medium** | `wit` | **13** | **+150** | 0 | 45% | 65% | 80% |
| **Hard** | `heart` | **18** | **+350** | **−4** | 20% | 40% | 55% |

Reading it:
- **Safe (+15)** is *below* break-even (60). Doing nothing bleeds you out — slowly,
  so it's tension, not instant death. This is the lever that makes Last Call a
  *choice you drift into*, not a punishment.
- **Easy (+60)** ≈ break-even early. It keeps you alive but never wins the game.
- **Medium (+150)** and **Hard (+350)** are how you actually climb. Hard is a
  gamble early (20%) and the reason to pour coin into Heart.
- **`regret_delta −4` on Hard:** regret starts at 20; ~**3 Hard successes** (−12)
  drops you into the low-regret bucket (≤10) for the "at peace" endings. So the
  players who keep choosing the honest, hardest answer are exactly the ones who
  earn the quiet endings. Theme, mechanized.

Tuning knobs, in priority order: **cadence** (global difficulty), **Hard reward**
(how much a clutch confession is worth), **Safe reward** (how forgiving stalling is).

---

## 3. Economy (drop into `Generator` / `StatUpgrade` `.tres`)

Give the player **~20 starting coin** (or a click-to-serve button) to buy the first
generator. Costs scale on purchase; income is linear in units owned × level.

### Generators (`buy_cost = base_cost * 1.15^owned`)

| Job | `base_cost` | `base_income` (coin/s each) | Rough "affordable by" |
|---|---|---|---|
| **Pour Drinks** | 10 | 1 | 0:00 |
| **Cook Food** | 120 | 9 | ~3–5 min |
| **Hire a Bard** | 1,300 | 70 | ~8–11 min |
| **Rent Rooms** | 15,000 | 550 | ~15+ min |

Classic ~10× idle tiers: each new job costs ~10× the last and pays ~8–9× more, so
"save for the next tier vs. buy more of this one" is a live decision all run.

### Stat upgrades (`cost = base_cost * 1.6^bought`, `amount = +1`)

| `stat` | `base_cost` | Costs for +1…+6 | Cumulative to +6 |
|---|---|---|---|
| charisma / wit / heart | **25** | 25, 40, 64, 103, 164, 263 | **~659 coin** |

`1.6^n` is steeper than the generator curve (`1.15^n`) on purpose: stats are power,
so they should compete hard with reinvesting in income. Focusing one stat to ~+5/+6
costs ~650 coin — roughly one mid-game generator tier's worth, forcing the
earn-vs-improve tension the whole loop is built on.

> **Never** author a `regret` stat upgrade. It's hidden and story-only.

---

## 4. A sanity-check run (what "working" looks like)

Not a precise sim — a shape to validate against once the loop runs:

- **0:00** — Buy 1–2 Pour Drinks. Timer at 300 (5 min of buffer; you won't die
  early). Coin trickles in.
- **~1:00** — First dialogue section. Early stats = 1, so you reliably clear **Easy**
  (70%), gamble **Medium** (45%). Bank your first real time.
- **~3–5 min** — Enough coin for **Cook Food** *or* your first couple of stat
  upgrades. This is the first meaningful fork.
- **~8–11 min** — A **Bard** and/or a stat at ~+4/+5. **Medium** is now ~65%+ and
  **Hard** is a real option (~40%). Net gain per section climbs past ~195.
- **~15 min** — You're clearing **Hard** often. Each success is +350 and −4 regret.
  A few of these vault you toward 3000.
- **~18–22 min** — Cross `win_threshold` → **Reprieve**. If you leaned into Hard
  confessions, regret ≤ 10 → the *earned peace* ending; if you brute-forced it with
  Medium/economy and dodged the honest answers → the *hollow win* ending.

**Validation checks to run first (before fine-tuning anything else):**
1. Does a **safe-only** player die? (They should — confirms stalling routes to Last
   Call.) Safe 15 < cadence 60 makes this true.
2. Does a **skilled** player win in ~18–22 min, not 6 or 45? Adjust **cadence** and
   **Hard reward** to move this.
3. Is coin ever a dead resource? If you can buy everything you want by min 10, raise
   `base_cost`s or the `1.6` stat exponent. If you can never afford a stat, lower them.
4. Does regret reach ≤10 for a Hard-leaning player but stay >10 for an economy-leaning
   one? Tune `regret_delta` / the bucket cutoff (`≤10`) so both ending columns are
   actually reachable.

---

## 5. Phase plan — one session each

Build so you **always have a losable game**. Each phase closes with something you can
run. Aim to reach the end of **Phase 5 (closed loop) by roughly the halfway mark**;
Phase 6 is content + polish, where GMTK is won.

### Phase 0 — Skeleton
- **Goal:** project runs, global state exists.
- **Build:** confirm `GameState` autoload is registered; empty `main_scene` with a
  root layout; pinned `CanvasLayer` for the countdown (empty label is fine).
- **Done when:** game launches, `GameState.time_remaining` visibly counts down in a
  debug label.

### Phase 1 — Countdown + endings
- **Goal:** the spine — a game you can lose and win.
- **Build:** countdown UI reads `time_changed`; `game_over(reason)` swaps in an
  ending scene; two placeholder ending texts (`timeout`, `time_won`); wire the
  regret bucket branch (four placeholder texts).
- **Done when:** you can sit and watch it hit 0 → Last Call, and (via a debug
  `add_time`) cross 3000 → Reprieve.

### Phase 2 — Turn-your-head layout + dialogue shell
- **Goal:** the two-panel scene and a talking Death.
- **Build:** 2×-width sliding `Control` with `DialoguePanel` / `TavernPanel`;
  `face()` tween + input to turn; "Death is waiting" nudge; DialogueManager state
  machine showing `reaper_blocks`, advancing, revealing options on the last block;
  **one hardcoded section** whose buttons just call `add_time`.
- **Done when:** you can turn your head, click through Death's lines, pick an option,
  and watch the timer jump.

### Phase 3 — Tiered checks + data-driven sections
- **Goal:** dialogue becomes a real gamble.
- **Build:** `DialogueSection` / `DialogueOption` Resources; `_roll_check` +
  `success_chance` odds display; Safe + one-per-stat tiers reading `GameState.stats`;
  apply `regret_delta`; move the Phase-2 section into a `.tres`. Use the §2 table.
- **Done when:** options show live % odds, you can fail a Heart check and get the
  fail beat, and a Hard success drops regret.

### Phase 4 — Tavern earns coin
- **Goal:** the earn side of the loop.
- **Build:** `Generator` Resources + an `Economy` tick adding coin; `TavernPanel` UI
  to buy generators; coin readout. Use the §3 generator table.
- **Done when:** coin accrues passively and you can buy more generators to earn faster.

### Phase 5 — Upgrades close the loop
- **Goal:** the full earn → improve → survive loop.
- **Build:** generator upgrades (raise `level`); `StatUpgrade` Resources spending
  coin to raise charisma/wit/heart; both wired through `spend_coin`/`bump_stat`.
- **Done when:** you can grind coin, buy a Heart upgrade, and *watch a dialogue
  option's odds go up* as a result. **This is the vertical slice.**

### Phase 6 — Content, juice, balance
- **Goal:** turn the system into the game.
- **Build:** write the real dialogue sections + backstory + `regret_delta`s; more
  generators; the four ending texts; audio; juice (timer heartbeat, `+time` popup,
  turn-head polish); **balance pass** against §4's validation checks. Optional
  stretch: `Codex` flags + Fallout-style end-cards.
- **Done when:** it's submittable and it makes someone feel something.

---

*Numbers here are a coherent starting point, not gospel. Trust the §4 validation
checks over any single value.*
