# Death's At The Door — Design & Architecture Doc

> **GMTK Jam 2026 — Theme: "Countdown"**
> Godot 4.6.3, 2D. Working title: *Death's At The Door* (placeholder).

---

## 1. Concept

You are a tavern-keeper. The **God of Death** has arrived to collect you — but by
old custom, Death will not take a keeper while their tavern is still open and
serving. So you throw a **bar-athon**: keep the customers coming, keep the doors
open, and keep Death talking. The countdown at the top is not your life — it's
**Death's patience**. When it runs out, patience ends and so do you.

- **Surface tone:** flippant, deflecting, joking. The keeper refuses to take this
  seriously and tries to charm, out-wit, or stall their way out.
- **Undertone:** through the conversation, Death draws out who this person was —
  their regrets, the choices they didn't make, the things left unfinished. The
  jokes are a bar rag thrown over grief.

### Win / lose states
- **"Reprieve" (win):** grow banked time past a **safe threshold** → Death, amused
  or moved, leaves you be (for now).
- **"Last Call" (secret / true ending):** let the timer hit zero → you stop
  running and let Death take you. Tonally the *quiet* ending, not the failure one.
- Endings are driven by signals (`game_won` / `game_over`) and swap in an ending
  scene. Keep them cheap: full-screen text, slow fade, one good line.

### Hard constraint: ~1 hour max runtime
A full playthrough must fit in **~1 hour**, ideally landing a satisfying run at
**15–30 minutes**, with 1 hour as the outer cap. This drives every number: the
starting timer, income rates, upgrade costs, and the win threshold are all tuned
so the loop resolves inside that window. See §8.

---

## 2. Two-layer core loop

The game runs **two systems at once**:

1. **Background layer — the tavern (idle economy).** Always running in real time.
   Generators (tavern jobs) produce coin every frame. The player buys and upgrades
   generators. This is the "something to do with your hands" idle-tycoon layer.
2. **Foreground layer — the conversation (dialogue encounters).** Punctuated.
   Death periodically opens a **dialogue section**. Winning stat-checks here is
   where the **big time swings and all the story** happen.

```
        EARN                         SPEND / RISK
  ┌──────────────────┐        ┌──────────────────────────┐
  │  Tavern jobs     │  coin  │  Stat upgrades           │
  │  (generators)    ├───────►│  (Charm / Wit / Heart)   │
  │  passive income  │        │                          │
  └──────────────────┘        └───────────┬──────────────┘
           ▲                              │ better odds
           │ coin buys generator upgrades ▼
           │                    ┌──────────────────────────┐
           └────────────────────│  Dialogue checks         │
                                │  success → +time, +story │
                                └───────────┬──────────────┘
                                            ▼
                                  COUNTDOWN (Death's patience)
                                  reach threshold → Reprieve
                                  hit zero → Last Call
```

The two layers never talk to each other directly — they meet in the middle at the
global `GameState` (coin, stats, time). That decoupling is what lets you rebuild
any one piece late in the jam without breaking the others.

---

## 3. Architecture idioms (do these first, they save the most time)

1. **One autoload singleton, `GameState`**, holds all global state: `time_remaining`,
   `coin`, `stats`, ownership, flags. Everything reads from it and listens to its
   signals.
2. **Signals over polling.** `GameState` emits `game_over` / `game_won` / `time_changed`
   once; UI connects and reacts. No script hunts for `if time <= 0` every frame.
3. **Data-driven content via custom `Resource` classes.** Dialogue sections,
   options, generators, and upgrades are authored as `.tres` files, not code.
   Writing content = filling out a form in the inspector. This is the single most
   important speed decision, because *content is the game.*
4. **Scene composition, small scenes.** Countdown bar, dialogue box, tavern/shop
   panel, ending screen, codex screen — each is its own scene instanced into a
   main scene.

---

## 4. `GameState` autoload — the heart

```gdscript
# GameState.gd  (registered as Autoload "GameState")
extends Node

signal time_changed(new_time)
signal time_added(amount)        # juice: floaty "+30s"
signal coin_changed(new_coin)
signal stat_changed(stat, value)
signal game_over(reason)         # "timeout" -> Last Call ending
signal game_won()                # crossed the safe threshold

var time_remaining := 90.0       # seconds (tune)
var win_threshold := 300.0       # tune; reachable inside ~1 hr
var is_running := true

var coin := 0
var stats := { "charm": 1, "wit": 1, "heart": 1 }   # names are placeholders

func _process(delta):
    if not is_running: return
    time_remaining -= delta
    time_changed.emit(time_remaining)
    if time_remaining <= 0.0:
        is_running = false
        game_over.emit("timeout")
    elif time_remaining >= win_threshold:
        is_running = false
        game_won.emit()

func add_time(amount):
    time_remaining += amount
    time_added.emit(amount)
    time_changed.emit(time_remaining)

func add_coin(amount):
    coin += amount
    coin_changed.emit(coin)

func spend_coin(amount) -> bool:
    if coin < amount: return false
    coin -= amount
    coin_changed.emit(coin)
    return true

func bump_stat(stat, amount):
    stats[stat] += amount
    stat_changed.emit(stat, stats[stat])
```

### Stats (placeholders, tune to taste)
Three stats map cleanly onto three dialogue option tiers per section:
- **Charm** — flirt, flatter, deflect. The keeper's easy patter.
- **Wit** — jokes, cleverness, arguing Death into a corner.
- **Heart** — sincerity, earnest truth. The hardest, highest-reward, and where
  the story cuts deepest (the honest answers reveal the most).

---

## 5. Countdown

The timer UI is a **dumb view**: it connects to `time_changed` and updates a
`Label`/`ProgressBar`. It holds no logic. `time_added` triggers a juicy popup.
Consider a color/heartbeat shift as `time_remaining` gets low, and a marker on the
bar showing the `win_threshold` so the player can see the finish line.

---

## 6. Dialogue system (REVISED — the structural change)

Your dialogue is **not** a flat list of options. A **section** is:

> one or more **God-of-Death text blocks**, advanced one at a time; on the **last
> block**, the **player options** appear.

And the options are a **fixed tiered set**, authored **easiest first, hardest last**:
- **Option 0 — Safe:** no check (or a trivial low check). Always/almost-always
  succeeds. Small time reward. The "you're never fully stuck" floor.
- **Option 1..N — one per stat:** each is a check against a single stat, ordered by
  ascending difficulty (e.g. Charm easy → Wit medium → Heart hard). Higher
  difficulty → **bigger time reward** and **more backstory** on success.

This means the player always sees a risk ladder: a guaranteed nibble, or gamble on
a stat for a bigger bite. Show the success **odds** next to each risky option
(Fallout / Disco Elysium style) — it makes every pick a real decision.

### 6a. Data schema

```gdscript
# DialogueSection.gd
class_name DialogueSection extends Resource

@export var reaper_blocks: Array[String]        # shown one at a time
@export var options: Array[DialogueOption]      # authored easiest -> hardest
@export var next_section: DialogueSection       # or drive order from a queue

# DialogueOption.gd
class_name DialogueOption extends Resource

@export var text: String                        # "[Heart] Tell the truth"
@export var stat: String = ""                   # "" = safe/no-check option
@export var difficulty: int = 0                 # DC; 0 for safe
@export var time_reward: float = 15.0           # scales with difficulty
@export var backstory_id: String = ""           # codex entry unlocked on success
@export var success_blocks: Array[String]       # Death's reaction on success
@export var fail_blocks: Array[String]          # Death's reaction on failure
```

Authoring convention: order `options` easiest→hardest so the UI can just list them
top-to-bottom. `success_blocks` / `fail_blocks` are themselves block arrays, so a
result can be a multi-line beat, not one line. **This is where the tone lives** —
especially `fail_blocks`, where the joke doesn't land and Death answers with
something quietly human.

### 6b. The manager is a small state machine

```gdscript
# DialogueManager.gd
enum { SHOWING_BLOCKS, AWAITING_CHOICE, SHOWING_RESULT, IDLE }
var state := IDLE
var section: DialogueSection
var block_i := 0

func start_section(s: DialogueSection):
    section = s
    block_i = 0
    _show_current_block()

func _show_current_block():
    var blocks = section.reaper_blocks
    show_reaper_text(blocks[block_i])
    if block_i == blocks.size() - 1:
        reveal_options(section.options)   # options appear ON the last block
        state = AWAITING_CHOICE
    else:
        hide_options()
        state = SHOWING_BLOCKS

func on_advance():                        # click / spacebar
    if state == SHOWING_BLOCKS:
        block_i += 1
        _show_current_block()
    elif state == SHOWING_RESULT:
        _advance_result_or_finish()

func on_option_chosen(opt: DialogueOption):
    if state != AWAITING_CHOICE: return
    hide_options()
    var success = _roll_check(opt)
    var blocks = opt.success_blocks if success else opt.fail_blocks
    if success:
        GameState.add_time(opt.time_reward)
        if opt.backstory_id != "":
            Codex.unlock(opt.backstory_id)
    _play_result_blocks(blocks)           # steps through, then finish_section()
    state = SHOWING_RESULT

func _roll_check(opt: DialogueOption) -> bool:
    if opt.stat == "": return true                    # safe option
    var roll = randi_range(1, 20) + GameState.stats[opt.stat]
    return roll >= opt.difficulty

func success_chance(opt: DialogueOption) -> float:
    if opt.stat == "": return 1.0
    var need = opt.difficulty - GameState.stats[opt.stat]  # min d20 face to hit
    return clamp(float(21 - need) / 20.0, 0.05, 0.95)      # for the UI %
```

Flow recap: `start_section` → advance through `reaper_blocks` → options reveal on the
last block → pick → roll → play `success/fail_blocks` → `finish_section()` →
either queue the next section or return to the tavern until Death opens the next one.

### 6c. When do sections fire?
Simplest: a **queue of sections** that Death opens on a cadence (e.g. every N
seconds of tavern time, or after each customer milestone). Keep the trigger dumb
for the jam — a timer or a counter — and author the sections in narrative order.

### Why roll your own (not Dialogic/Ink)
Your dialogue isn't branching prose — it's a **sequence of gambling encounters in a
dialogue costume**, with a bespoke tiered-check + add-time mechanic. Rolling your
own is *less* code than bending a dialogue plugin to this shape, and it makes the
check the first-class citizen. If you want a fancier textbox (typewriter, portrait),
a `RichTextLabel` + a tween is ~20 lines and won't fight your logic.

---

## 7. Economy — tavern jobs (generators) + upgrades

### 7a. Generators = tavern jobs (idle income)
Author several as Resources: **Serving drinks, Cooking food, Bards/entertainment,
Hotel rooms**, etc. Each is a passive coin source the player can own multiple of and
upgrade independently.

```gdscript
# Generator.gd
class_name Generator extends Resource

@export var name: String                  # "Pour Drinks", "The Kitchen", "Hire a Bard"
@export var flavor: String
@export var base_cost: int
@export var base_income: float            # coin / sec per unit owned
@export var owned := 0
@export var level := 1                    # its own upgrade track

func buy_cost() -> int:                    # cost of the NEXT unit
    return int(base_cost * pow(1.15, owned))

func income_per_sec() -> float:
    return base_income * owned * level     # or your preferred level curve
```

```gdscript
# Economy.gd  (a node, or fold into GameState)
@export var generators: Array[Generator]

func _process(delta):
    var total := 0.0
    for g in generators:
        total += g.income_per_sec() * delta
    GameState.add_coin(int(total))   # accumulate fractional coin somewhere if needed
```

Standard idle scaling: **buy cost `= base * pow(1.15, owned)`** (see "cookie clicker
cost formula"). Give each job flavor that serves the theme — the keeper doing
increasingly frantic, slightly tragic things to keep the lights on. Tie some flavor
text to the backstory where you can.

### 7b. Two upgrade tracks
Both spend the same `coin`, so the tavern layer funds the dialogue layer:
1. **Generator upgrades** — raise a specific job's `level` / income. Separate per
   generator, as you wanted.
2. **Stat upgrades** — raise Charm / Wit / Heart, improving dialogue odds.

```gdscript
# StatUpgrade.gd
class_name StatUpgrade extends Resource
@export var stat: String
@export var amount: int
@export var base_cost: int
@export var bought := 0
func cost() -> int: return int(base_cost * pow(1.6, bought))   # steeper than generators

func try_buy_stat(u: StatUpgrade):
    if GameState.spend_coin(u.cost()):
        GameState.bump_stat(u.stat, u.amount)
        u.bought += 1
```

Because both the shop and the dialogue read the same `GameState.stats`, the loop
closes automatically: **earn → upgrade → better odds → more time → survive.** You
never wire those systems to each other directly.

---

## 8. Balancing to the 1-hour cap

Tune so a *full* run resolves well under an hour; target a satisfying win around
15–30 min. Rough levers:
- **Start timer** low enough to feel the pressure immediately (~60–120 s), but with
  an early easy win-check that teaches "dialogue buys time."
- **Win threshold** reachable only by winning several mid/hard checks *and* running
  the economy — so both layers matter.
- **Income & costs** curved (`pow(1.15, owned)` for generators, steeper for stats)
  so the player is always ~30–60 s from their next meaningful purchase.
- **Do balance last**, with the real loop running. Data-driven Resources make
  re-tuning painless — change numbers in the inspector, not code.
- Consider a soft **anti-stall**: if the timer creeps toward zero, Death's next
  section offers a slightly-easier check, so a losing run still gets its story beats
  before Last Call.

---

## 9. Story delivery — the Codex

A tiny autoload carries the emotional payload:

```gdscript
# Codex.gd (Autoload)
signal entry_unlocked(id)
var unlocked := {}
func unlock(id):
    if not unlocked.has(id):
        unlocked[id] = true
        entry_unlocked.emit(id)
```

Each successful **hard (Heart)** check drips a regret. A simple codex screen lists
revealed entries. Mechanical success = narrative revelation: the harder the keeper
fights to live, the more we learn about what they can't bear to leave undone. That
*is* the theme, mechanized.

---

## 10. Build order — the dependency spine

Build so you **always have a losable game.** Each phase adds one link and leaves
something playable. Aim to **close the full loop (end of Phase 5) by ~the halfway
mark**; everything after is content + polish, which is where GMTK is won.

| Phase | Build | Leaves you able to… |
|---|---|---|
| **0** | Project, `GameState` autoload, main scene skeleton | — |
| **1** | Countdown + win/lose signals + ending scenes | Sit and watch the clock run out. |
| **2** | Dialogue box: show reaper blocks, advance, reveal options on last block; hardcode one section that adds time | Talk Death into +time. |
| **3** | Tiered options + check math + odds display, reading `GameState.stats`; move sections to `.tres` | Gamble a stat check and whiff. |
| **4** | One generator earning coin + coin UI | Grind the tavern for coin. |
| **5** | Generator upgrades **and** stat upgrades → **loop closes** | Actually strategize. |
| **6** | Content: write sections/backstory, more jobs, juice, audio, both endings, **balance** | Feel something. |

---

## 11. Scope guard (decide the cuts now)

- **Placeholder everything** (grey boxes, `Label`s) until Phase 6. Don't open the
  art program before the loop closes.
- **If behind at ~70% of time:** cut extra generators (keep 1–2), cut extra
  sections (keep a short authored arc), cut any active minigame (keep passive
  income), keep win + Last Call endings only.
- **Never cut:** the countdown, the tiered dialogue check, and one working
  earn→upgrade→spend loop.
- **Balance is last**, always, with real numbers.

---

## 12. Resource schema summary (author these as `.tres`)

| Resource | Key fields |
|---|---|
| `DialogueSection` | `reaper_blocks[]`, `options[]`, `next_section` |
| `DialogueOption` | `text`, `stat`, `difficulty`, `time_reward`, `backstory_id`, `success_blocks[]`, `fail_blocks[]` |
| `Generator` | `name`, `flavor`, `base_cost`, `base_income`, `owned`, `level` |
| `StatUpgrade` | `stat`, `amount`, `base_cost`, `bought` |

---

## 13. Learning resources

- **Autoload / singletons:** Godot Docs → *Singletons (Autoload)* —
  `docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html`
- **Signals:** Godot Docs → *Using signals* —
  `docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html`
- **Custom Resources (`class_name … extends Resource`, `@export`, `.tres`):**
  Godot Docs → *Resources* —
  `docs.godotengine.org/en/stable/tutorials/scripting/resources.html`
  Also search **"Godot 4 data-driven design custom resource"** (GDQuest, Bitlytic).
- **State machine for the DialogueManager:** search **"Godot 4 finite state machine
  GDScript"** (GDQuest has a canonical write-up); an `enum` + `match` is plenty here.
- **Idle / incremental patterns:** search **"Godot 4 idle incremental tutorial"**;
  cost curve reasoning: **"cookie clicker cost formula"** (`base * 1.15^owned`).
- **RichTextLabel / typewriter text:** Godot Docs → *RichTextLabel*, plus search
  **"Godot 4 typewriter text tween"**.
- **General Godot recipes:** KidsCanCode *Godot Recipes* — `kidscancode.org/godot_recipes/`
  (use the 4.x sections).

---

*This doc is architecture + intent, not final numbers. Every value here is a
placeholder to be tuned against the 1-hour target once the loop runs.*
