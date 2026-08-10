# SOUL EVOLUTION — CRITICAL BRIEF v1
_For another agent (Claude) to hold, regurgitate, and re-reason over._
_Write date: 2026-08-?? — from Luka, via Cline._

## 1. THE MYTHOS (the story)
Light and Dark fought — and fight still — for space. Time facilitated the
fight. **Time is the narrator and the trader**: the voice that names, the
hand that exchanges substance between the two.

Light and dark notice only what is theirs. White sees only white, black only
black. Each is structurally blind to the other's value.

**The world is grey not because color is absent, but because neither side can
see what belongs to the other.** Color/substance appears when Time facilitates
perception — when light finally sees dark's value, and vice versa.

## 2. THE PHYSICS (the mechanism — three states)
- White = electron (matter). Black = positron (antimatter).
- Matter + antimatter contact → **annihilation** → energy released as COLOR
  (substance) AND **neutralization into neutrons** — a THIRD state, neither
  white nor black.
- **Grey is the accumulation of the lost.** Every annihilated pair becomes
  neutral residue. The world does NOT sit in static monochrome — it is
  *becoming* grey, fed by every soul lost to neutralization.
- The fighting lasts eternity; white and black lose many to neutralization.

## 3. THE CYCLE (the game loop — acts)
1. **The Eternal War** — battle, annihilation, color + neutron production.
2. **The Greying** — as souls neutralize, grey accumulates. The heaviness of
   movement grows.
3. **The Grand Council** — when enough is lost, movement LOCKS (heaviness).
   The last members of black and white are forced to meet and negotiate.
   Options: **full domination of one color**, OR **splitting of resources**.
   Both fail against the truth: one cannot exist without the other.
4. **The Rebirth** — color REAPPEARS on the grand map, the fight AMPLIFIES,
   each side gains a FEAT, and the grind continues.

## 4. THE TRUTH (the meaning)
There is no final victory. The cosmos breathes: fight → grey → council → rebirth
→ amplified fight. The only stable truth — shown, not told — is that **one
cannot exist without the other**. Matter needs antimatter to release energy;
neither creates alone. Two hands of one being, clapping; Time is the air.

## 5. THE META (the real "evolution")
The eternal war is NOT static. Across cycles:
- Each side gains a **FEAT** (permanent ability) at the council rebirth.
- **Color DENSITY** accumulates — the world becomes richer every cycle.
- **EXPERIENCE** compounds.
The player is not trying to win — they are trying to make the cycle RICHER:
more density, more experience, deeper color. Grind with meaning. This is
"Soul Evolution" — not of one soul, but of the entire plane across eternity.

## 6. CRITICAL TENSIONS (for re-reasoning)
- **Domination vs splitting**: both are shown to be false ends. What does the
  player actually CHOOSE at the council, and what does each choice cost?
- **Feats as permanent drift**: if each cycle grants a feat, the war escalated
  infinitely. When does a feat become its own kind of grey (over-power = loss
  of meaning)?
- **The trader's role**: Time trades. What does Time ASK in exchange for the
  color it reveals? The economy of the trade is the untold mechanic.
- **Neutrons as the forgotten**: the neutralized souls are the grey — are they
  the world's memory, its foundation, or its decay? Can a neutron regain color?

## 7. THE NOT-YET-BUILT (next priority)
1. Three-state physics: annihilation → color + neutron (grey accumulation).
2. Monochrome-as-blindness: light literally cannot perceive dark until color
   emerges (and vice versa).
3. The Grand Council: movement locks, last members negotiate, choice, rebirth.
4. Feats + color density + experience: the meta-cycle.
5. Time as trader: the economy of perception.
6. The 12 axes + windows + word-protocol: the fabric and the tradable art.

## 8. CLAUDE'S RE-REASONING (2026-08-10)
Re-reasoned, not just restated — each answer below is chosen so it reuses a
system that already exists in the code (concealment, hex terrain, world_color,
death_count) rather than inventing a disconnected new one. That's a deliberate
bias: a mechanic that shares plumbing with something already built and tested
is more likely to actually ship than a fifth parallel subsystem.

**Domination vs splitting — what's actually chosen, what it costs.**
Both being "false ends" only means something if picking one has a real,
different cost from picking the other — otherwise it's a coin flip with
narration on top. Proposal: **domination doesn't hold.** If the council picks
domination, the world doesn't let a single color persist — the system forcibly
reconverts a fraction of the dominant color's own members back to the
opposite polarity (say 30%), because annihilation (the thing that makes color)
requires two colors, and a mono-color world can't produce it. So domination
costs you a self-division tax, paid *after* the choice, at a worse ratio than
you had. **Splitting** costs the same tax, but paid *up front*, evenly, and
voluntarily — no post-choice penalty. Mechanically: splitting is the
efficient choice; domination is the vain one that the plane corrects for you.
"One cannot exist without the other" stops being a line the narrator says and
becomes a rule the simulation enforces.

**Feats as infinite escalation — when a feat becomes its own grey.**
Don't cap feats with a hard ceiling (anti-thematic — the cycle is eternal, a
ceiling isn't). Instead, couple every feat's power gain to a *perception*
cost: each feat a side accumulates widens that side's blindness radius — the
concealment mechanic built today (`_update_concealment` in `main.gd`, dark
zones fading black souls from a white viewer) is already the exact
machinery for this. A heavily-feated side gets stronger and, mechanically,
worse at seeing the other side coming — the escalation devours its own
danger sense. Power without perception reproduces the original blindness
that started the war. This isn't a new system — it's `reveal_radius` in
`_update_concealment` scaling down (or `T_DARK` fade-alpha scaling up) with
accumulated feat count.

**Time as trader — what it takes for the color it reveals.**
It takes *duration itself*, and this is almost already true in the current
code, just not named: every annihilation both raises `world_color` (reveals
color) and raises `death_count` (which is what should drive the Grand
Council's movement-lock threshold once that's built). Made explicit: **the
faster color is revealed, the faster the current Act ends.** Time doesn't
hand out color for free — spending it accelerates your own approach to the
Council. This reframes "grinding for color" as a real tension instead of a
pure upside: more annihilation = more color now, but also a shorter Eternal
War before the next lock.

**Neutrons as the forgotten — memory, foundation, or decay; can they return?**
Foundation, not memory or pure decay. **Refined 2026-08-10 (Luka's read, sharper
than my first pass):** don't make the neutron an invisible terrain-tile flag —
make it the soul's own broken body. At the moment of neutralization, the
sphere doesn't vanish, it loses its round form: it fractures into broken/split
shard pieces and *becomes* the object left behind — inert, grey, physically in
the way. Mechanically this reuses `main.gd`'s existing obstacle system
(`obstacle_rects`/`obstacle_hp`/`obstacle_max_hp` — already blocks movement,
takes beam damage, gets pushed by force fields) instead of inventing a new
terrain type: spawn a neutron-remnant obstacle at the annihilation contact
point, shaped like broken shards (echoing the black soul's faceted look, but
inert). That's what makes "movement grows heavy" literal — the arena fills
with wreckage from its own war, not a global slowdown multiplier. And yes,
**a neutron can regain color**: a later annihilation near enough to a
neutron-remnant should crack it back open (destroy the obstacle, feed
`world_color`) — old wreckage is reclaimable by new conflict, not permanently
spent.

## 9. THE RESOURCE ECONOMY + A DESIGN CONSTRAINT (2026-08-10, Luka + Claude)

**"Dust of ?"** — Luka asked what grinding down neutron-remnants (already-broken
pieces) produces, if annihilation itself produces color+neutron. Answer:
**dust** — a third, lower resource, one tier below color. Chain: matter +
antimatter → color (rare, world-level) + neutron (a broken object, physical).
Neutron + more violence → dust (common, grindable, formless — the residue of
breaking what's already broken). This isn't a new resource system bolted on:
it's the *existing* `upgrade_points` economy in `soul_genome.gd`
(`spend_upgrade` for laser_dmg/laser_rng/devour_win/devour_bst/speed),
currently earned generically from "destroy any obstacle." Once
neutron-remnants exist as obstacles (§8), destroying *those specifically*
should be the dust source — giving the already-built character-upgrade system
an actual place in the mythos instead of being an unexplained side mechanic.
Net economy, three tiers: **dust** (common, character-level, spend on your own
build) → **color** (rarer, world-level, changes what everyone sees) →
**feats** (rarest, cycle-level, survive to the Council to earn one). Different
scarcity, different scope, same underlying act of violence.

**"The game does not give knowledge lightly"** — treated as a hard constraint,
not a suggestion. This is already mostly honored: `character_sheet.gd` shows
raw symbols (`div`, `neg`, `del`, `trace`, `tau`, `sig`, `C`, `N`, `P`, `S`,
`Psi=0.xxx`) with no tooltip explaining what any of them mean or do. Keep it
that way going forward — no explanatory tutorial text, no "dust: use this to
upgrade your abilities" popup. If dust/neutron/council mechanics get built,
they should be as opaque on first contact as `Psi(x) = div_inf(pi(x)) /
neg(neg(x)) + del*x * trace` already is. Understanding is something a player
earns by playing, not something the UI hands them — consistent with the
narrator's own line already in `main.gd`: *"only in doubt is movement
possible."*

**Character building is integral, not a side panel** — this reframes what the
three-tier economy above is *for*. The genome/abilities/upgrade system already
exists but is thin (5 linear upgrade categories). If it's a core pillar, dust
scarcity and feat rarity are what should make spending choices actually
matter, and the still-unbuilt 12 axes (`DESIGN.md`) are a plausible home for
real build depth beyond the current 5 categories — not yet resolved, next
design pass.

## 11. THE HOURGLASS — SAND TRADED WITH TIME (2026-08-10, Luka)

Refines §9's "dust": dust *is* sand — the literal grain, not a metaphor. It is
**gathered in hourglasses** and **traded with Time for change/resources**.
This resolves the open tension from §8 ("what does Time ask in exchange for
the color it reveals?") with something concrete instead of an abstract
"duration" answer: **Time's role stops being purely narrative the moment
there's an hourglass to pour sand into.** An hourglass is the one object
whose entire function is measuring time — so trading sand into one isn't a
metaphor for trading with Time, it's the literal mechanism.

Per the correction above, this is its own system, not a re-skin of
`upgrade_points`: an **hourglass** is a container the player fills with sand
(gathered from destroying neutron-remnants, §8/§9) and can, at will, pour out
— trading it to Time for "change" (conversion: sand into a different
resource — color, a feat-fragment, a reroll) or "resources" (a direct grant).
Open question this raises, not yet resolved: is the exchange rate fair, or
does Time (as trader) take a cut — and does *pouring* the hourglass also cost
duration the way §8 proposed (spending sand accelerates the current Act
toward the Council), making the hourglass a literal dial on pacing as well as
a currency exchange? Both readings are consistent with everything built so
far; which one Luka means changes whether the hourglass is primarily an
economy object or primarily a pacing object.

**What this doesn't resolve (still open, deliberately):** none of the above
is built — it's a design resolution, not code. The Grand Council's actual UI
/ negotiation flow, the exact feat list, and the neutron-tile conversion
threshold all still need a scoped implementation pass, one at a time, not
all at once. Suggested build order: neutron-as-terrain first (it's the one
with no dependencies and reuses the hex/concealment work already shipped
today) — everything else (Council, feats, Time-as-clock) depends on
`death_count`/`world_color` behaving as a real pressure gauge, which the
neutron-terrain change is what makes that pressure *visible on the map*
instead of only in a shader parameter.