# Soul Evolution — Design Notes

_Version: v3 — Mythos of Creation (realigned to the narrative heart)_

## THE MYTHOS OF CREATION
Long ago, Light and Dark fought — and fight still — for space.
Time facilitated the fight. Time IS the narrator and the trader:
- Time narrates what happens (the voice that names).
- Time trades the value between the two (the exchange of substance).

**Light and dark notice only what is theirs.**
White sees only white's substance. Black sees only black's. Each is blind to
the other's color. **That mutual blindness IS monochrome.** The world is grey
not because color is absent, but because neither side can perceive what
belongs to the other.

Color/substance emerges when Time facilitates the perception — when light
finally sees dark's value, and dark sees light's. The game is the story of
that emergence.

## THE MEANING (logical conclusion)
**Conflict creates the world.** White = electron (matter), Black = positron
(antimatter). When they meet → annihilation → both destroyed + energy
released as COLOR (substance). The B&W world saturates as souls annihilate.
The game is NOT "win the battle" — it is how the conflict, driven by Time,
constructs the reality. Matter needs antimatter to release energy; neither
creates alone. Two hands of one being, clapping; Time is the air between.

## Core identity
- **White soul = electron** — light beam is EM radiation. Courageous, direct.
- **Black soul = positron** — force field is EM repulsion. Ambushing, patient.
- **Time** = narrator + trader. The voice that names; the hand that exchanges.
- **Ego = player consciousness** — the field that excites. Original ego=1.0,
  reserves ego=0.0, incarnated ego=0.8.
- **Color = substance** — starts B&W, enters via annihilation/perception.
- **Monochrome** = the blindness of light and dark to each other's value.

## The 12 axes (the fabric of the plane)
prehod, beseda, um, smisel, značaj, prostor, čas, telo, tišina, pot,
resnica, dvom. Each soul carries a **word** from the corpus; each axis is a
realm/mechanic. (Not yet built — the next layer.)

## The windows (art to hoard / upgrade / trade)
Frames featuring art — generated from the corpus. Time (the trader) brokers
them. (Not yet built — was dropped early, now reclaimed.)

## Annihilation (the core mechanic — built)
White + black contact = both destroyed + colored flash + world_color +1.
The world desaturates LESS as world_color grows.

## Soul anatomy (built)
- **White**: SOLID bright sphere, light palette, dark outline, warm seep.
- **Black**: SOLID dark sphere, dark palette, light outline, cool seep.

## Abilities → spatial factors (built)
STR→mass · STA→size · INT→perception · WIS→vision · CHA→social gravity ·
DEX→speed · LUK→probability.

## Current state (built)
- Main menu → polarity → battle (20 vs 20)
- Soul-stream incarnation, ego system
- Hex maze terrain (rooms, corridors, dark/light, cover)
- Character sheet (7+8+4+genome)
- Narrator (sassy), visual effects, camera follow
- Annihilation creates color
- Blender pipeline (proven) — now also renders actual white/black soul sprite
  textures used in-game (`assets/white_soul.png`, `assets/black_soul.png`),
  not just the reference scene
- Auto-test (`--auto`)
- Real soul body assets: smooth radiant white sphere vs. faceted dark-crystal
  black — a silhouette-level distinction, not just a color difference
- Dark-zone concealment: black souls standing in `T_DARK` hexes fade toward
  near-invisible to a white viewer beyond ~160px (white has no night vision;
  black does) — see `_update_concealment` in `main.gd`
- Liquid/wave hex grid: the terrain now ripples continuously (a travelling
  wave, not per-hex noise) and bleeds toward a violet tint as `world_color`
  rises from annihilation — the map visibly *fights* rather than sitting static
- Fixed a real bug where every soul in both armies read the player's raw
  WASD/SPACE input (not just the controlled one) — movement/abilities are now
  gated behind `is_active`, set only on the player's current body
- **Neutron remnants + dust (the third state, built for real, not just
  designed)** — `scripts/neutron_remnant.gd`: annihilation now spawns a
  broken-shard physical object at the contact point, not just an abstract
  counter. It blocks movement (wreckage narrows the arena — "movement grows
  heavy" is now literal, not a slowdown multiplier), takes beam damage, and
  yields **dust** on destruction — a new resource, its own system, not folded
  into `substance`/`upgrade_points` (see CRITICAL_BRIEF.md §9's correction on
  this). A later annihilation near an existing remnant cracks it back open,
  feeding `world_color` again — reclaimed, not permanently spent. Verified
  end-to-end via `--auto`: annihilation → remnant spawns → beam destroys it →
  dust flows (`neutron_remnants=1` → fire → `neutron_remnants=0, dust=2`).
  Status: CANDIDATE — shipped and proven once, not yet reused/reinforced by a
  second, independent play session.

## THE CYCLE, THE THIRD STATE, AND THE META (see `CRITICAL_BRIEF.md`)
Distilled 2026-08-10 (Cline) and re-reasoned (Claude, same date) — full detail,
including four open tensions and answers, lives in `CRITICAL_BRIEF.md` so it
doesn't get lost to context; short version:
- Annihilation is **three-state**, not two: matter + antimatter → color AND
  **neutrons** (a third, neutral residue). Grey is not the starting condition —
  it's *accumulated* from every neutralized pair. The world is always either
  greying or recoloring, never static.
- **The Grand Council**: when enough souls neutralize, movement locks under
  the accumulated weight and the last members of each side are forced to
  choose — domination or splitting. Both fail against the underlying truth
  (one cannot exist without the other) — but the choice still has to be made,
  and it has to cost something, or it isn't a choice.
- **The meta-cycle**: feats, color density, and experience compound *across*
  cycles. The player isn't trying to win a battle — they're trying to make
  the plane's history richer. Not yet built. See `CRITICAL_BRIEF.md` §8 for
  the concrete resolution of what domination/splitting actually cost, what
  Time takes in the perception-trade, and what a neutron is.

## NOT YET BUILT (the narrative heart — next priority)
1. **Time as narrator/trader** — the narrator gains a trading role; the
   hourglass (`CRITICAL_BRIEF.md` §11) is the concrete mechanic proposed.
2. **Monochrome-as-blindness** — light and dark literally cannot see each
   other's substance until color emerges.
3. **The Grand Council** — movement-lock at high neutron-remnant density
   (built, §above — remnants already block movement), last-members
   negotiation, domination/splitting choice, rebirth with a feat each.
4. **Tile-color protection** — souls above 90% health deepen the color of the
   hex they occupy; deeper tiles protect/buff whoever stands on them.
5. **Fire/Air/Spirit/alignment** — an elemental layer alongside polarity;
   Spirit as an always-present (not event-triggered) field; player alignment
   (separate from polarity) determines whether it's a boon or a detriment.
6. **The 12 axes** as realms/mechanics from the corpus.
7. **The windows** — art from the corpus, hoarded/upgraded/traded by Time.
8. **Word-protocol** — each soul carries a word from the corpus.
