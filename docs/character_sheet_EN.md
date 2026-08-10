# Soul Evolution — Character Sheet Reference (EN)

> **Purpose:** The working reference for development. This is the file to build
> against. It documents the character sheet (`scripts/character_sheet.gd`) and the
> soul genome (`scripts/soul_genome.gd`) — every attribute, what it means, and
> what it correlates to.
>
> The Slovenian version (`docs/character_sheet_SL.md`) is kept for development
> reference when the original-language terms matter.

---

## What the character sheet is

The character sheet (opened with **TAB**) is a D&D-style panel built on the
canon's **Absolute / Immanence two-level model** (debate-log #033): every soul has
an **opaque-math layer** (the genome formulas) and an **embodied-meaning layer**
(the story/traces). It renders the **active playable soul** — or a **read-only
vault-stored soul** through the same template ("shared frame, honest depth").

Every soul is a blank ball whose identity is its **genome** — "the soul's DNA in
the plane."

---

## 1. The Genome (the plane's code) — 10 operator/element values, each 0–1

These are the ontomathematical identity — the genes:

| Symbol | Field | Meaning |
|---|---|---|
| ∇ | `divergence` | divergence / ecstasy — the cut as origin of movement |
| ¬ | `negation` | negation / doubt — the primal No, doubt |
| ∆ | `delta` | delta / transition — change |
| ✡ | `trace` | trace / character — **the gene that feeds COLOR** |
| τ | `tau` | tau / path — time-structure, the path |
| σ | `sigma` | sigma — discipline / the silence-pause |
| C | `carbon` | carbon — the body / foundation |
| N | `nitrogen` | nitrogen — the mind |
| P | `phosphorus` | phosphorus — the heart / emotion |
| S | `sulfur` | sulfur — the will / volition |

---

## 2. Abilities (the phenotype) — 7 D&D-style stats, 1–100

Each is **derived from the genome**:

| Ability | Formula (from genome) |
|---|---|
| **STR** (strength) | σ·0.6 + ∆·0.4 |
| **STA** (stamina) | σ·0.5 + C·0.3 + ¬·0.2 |
| **INT** (intellect) | ∇·0.5 + C·0.3 + N·0.2 |
| **WIS** (wisdom) | ¬·0.4 + N·0.3 + ✡·0.3 |
| **CHA** (charisma) | ✡·0.5 + P·0.3 + S·0.2 |
| **DEX** (dexterity) | τ·0.5 + S·0.3 + ∇·0.2 |
| **LUK** (luck) | random (0.3–1.0) |

---

## 3. The Equation — **Ψ (psi)**, 0–1

```
Ψ(x) = ∇∞(π(x)) ⊘ ¬¬(∴x) + ∆x✡
```

Implemented as: `psi = (divergence·π/τ) − (negation²) + (delta·trace)`.
The soul's ontomathematical power.

---

## 4. Pools

- `capacity_max = STA × 10` — the soul's life/spirit pool (stamina = volume).

---

## 5. The 8 Powers (the Box) — the ψ/body registers, each 0–1

| Power | Meaning | Formula |
|---|---|---|
| **fizicna** | physical | ✡·0.6 + ∆·0.4 |
| **psiholoska** | psychological | (¬ + N) · 0.5 |
| **custvena** | emotional | ✡·0.5 + P·0.5 |
| **duhovna** | spiritual | (¬ + N)·0.3 + ✡·0.7 |
| **dusevna** | soul | C·0.5 + N·0.5 |
| **inteligenca** | intelligence | ∇·0.5 + N·0.3 + C·0.2 |
| **gibljivost** | mobility | τ·0.5 + S·0.3 + ∇·0.2 |
| **stamina** | stamina | σ·0.5 + C·0.3 + ¬·0.2 |

---

## 6. The 4 Mithjos dynamics (Z·J·E·N) — the soul's living vector

| Symbol | Meaning | Formula |
|---|---|---|
| **Z** | zavest (consciousness) | C·✡ + ∇·0.3 |
| **J** | ego-relation | ∇·S + 0.2 |
| **E** | ethical process | ✡·P + 0.1 |
| **N** | paradox / "Ne" (No) | ¬·∆ + 0.1 |

---

## 7. Combat factors (abilities + powers → mechanics)

- **Laser damage** = STR·0.05 + fizicna·2 + laser-level
- **Laser range** = 300 + INT·2 + range-level
- **Devour damage** = STR·0.04 + dusevna·2 + level
- **Devour window** = 0.25 + WIS·0.003 + level
- **Speed** = 220 + DEX·1.5 + level
- **Reflex** = (DEX + WIS) / 2
- **Aura** = (CHA + LUK) / 2

---

## 8. Ego** (0–1) — player consciousness

Boosts all stats: effective = base × (1 + ego × 0.3).
- Original soul: ego = 1.0
- Reserves: ego = 0.0
- Incarnated: ego = 0.8

---

## 9. Story, skulls, modifications, upgrades

- **story_lines / fragments_touched** — the soul's narrative (the immanence layer).
- **skulls** — death count.
- **modifications** — mutations / upgrades / blessings / curses (each: type, name,
  stat, value, permanent).
- **upgrade_points + 5 linear upgrades** — laser damage/range, devour window/burst,
  speed.

---

## The correlation summary (how it all connects)

The genome (∇¬∆✡τσ C-N-P-S) → derives the **abilities** (STR..LUK) → derives the
**equation** (psi) → and the **powers** (8-box) and **mithjos** (Z·J·E·N) read the
same genes. The abilities + powers then feed the **combat factors**. The sheet is
the seam where the reaction/purpose systems attach: the operator-genes
(∇¬∆✡) are how the soul *forms reactions*, and mithjos (consciousness / relation /
ethics / paradox) is the *fuel* the ascending chain (MOLK→AKCIJA) converts into
purpose.

---

## Reaction + Purpose build targets (next)

- **Reaction-Formation:** the act's resonance reads the genome fields (∇¬∆✡τσ as
  the word's operators) and psi as the carrier quality — the ∅sentence
  `Sᵢ = α₁⊕α₂⊕...` maps each α onto ∇¬∆✡.
- **Reaction:** the echo/validator modifies mithjos (Z·J·E·N) and the powers in
  response to how the act landed.
- **Purpose-Fuel:** the ascending chain advances when mithjos / powers / psi reach
  thresholds — the traits on this sheet are what reactions feed and the
  purpose-ladder reads.