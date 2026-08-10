# Soul Evolution — Referenca Osebnega Kartona (SL)

> **Namen:** Slovenska različica za razvoj, ko so pomembni izvirni izrazi.
> Angleška različica (`docs/character_sheet_EN.md`) je tista, ki se razvija.
> Dokumentira osebni karton (`scripts/character_sheet.gd`) in genom duše
> (`scripts/soul_genome.gd`) — vsak atribut, kaj pomeni in s čim je povezan.

---

## Kaj je osebni karton

Osebni karton (odpreš s **TAB**) je plošča v slogu D&D, zgrajena na kanonovem
**dvostopenjskem modelu Absolutno / Imenenčno** (debate-log #033): vsaka duša ima
**matematično-nevidno plast** (genomske formule) in **utelešeno-pomensko plast**
(zgodba/sledi). Prikaže **aktivno, igralno dušo** — ali **samo-bralno dušo iz
arhiva** skozi isto predlogo ("skupni okvir, iskrena globina").

Vsaka duša je prazna krogla, katere identiteta je njen **genom** — "DNK duše v
ravnini."

---

## 1. Genom (koda ravnine) — 10 vrednosti operatorjev/elementov, vsaka 0–1

To je ontomatematična identiteta — geni:

| Simbol | Polje | Pomen |
|---|---|---|
| ∇ | `divergence` | razhajanje / ekstaza — rez kot izvor gibanja |
| ¬ | `negation` | negacija / dvom — prvotni Ne, dvom |
| ∆ | `delta` | delta / prehod — sprememba |
| ✡ | `trace` | sled / značaj — **gen, ki hrani BARVO** |
| τ | `tau` | tau / pot — časovna struktura, pot |
| σ | `sigma` | sigma — disciplina / premor tišine |
| C | `carbon` | ogljik — telo / temelj |
| N | `nitrogen` | dušik — um |
| P | `phosphorus` | fosfor — srce / čustvo |
| S | `sulfur` | žveplo — volja / hotenje |

---

## 2. Sposobnosti (fenotip) — 7 statov v slogu D&D, 1–100

Vsaka je **izpeljana iz genoma**:

| Sposobnost | Formula (iz genoma) |
|---|---|
| **STR** (moč) | σ·0.6 + ∆·0.4 |
| **STA** (vzdržljivost) | σ·0.5 + C·0.3 + ¬·0.2 |
| **INT** (inteligenca) | ∇·0.5 + C·0.3 + N·0.2 |
| **WIS** (modrost) | ¬·0.4 + N·0.3 + ✡·0.3 |
| **CHA** (karizma) | ✡·0.5 + P·0.3 + S·0.2 |
| **DEX** (spretnost) | τ·0.5 + S·0.3 + ∇·0.2 |
| **LUK** (sreča) | naključno (0.3–1.0) |

---

## 3. Enačba — **Ψ (psi)**, 0–1

```
Ψ(x) = ∇∞(π(x)) ⊘ ¬¬(∴x) + ∆x✡
```

Implementirano: `psi = (divergence·π/τ) − (negation²) + (delta·trace)`.
Ontomatematična moč duše.

---

## 4. Zaloge (Pooli)

- `capacity_max = STA × 10` — zaloga življenja/duha duše (vzdržljivost = volumen).

---

## 5. 8 Moči (Škatla) — registri ψ/telesa, vsak 0–1

| Moč | Pomen | Formula |
|---|---|---|
| **fizicna** | telesna | ✡·0.6 + ∆·0.4 |
| **psiholoska** | psihološka | (¬ + N) · 0.5 |
| **custvena** | čustvena | ✡·0.5 + P·0.5 |
| **duhovna** | duhovna | (¬ + N)·0.3 + ✡·0.7 |
| **dusevna** | duševna | C·0.5 + N·0.5 |
| **inteligenca** | inteligenca | ∇·0.5 + N·0.3 + C·0.2 |
| **gibljivost** | gibljivost | τ·0.5 + S·0.3 + ∇·0.2 |
| **stamina** | vzdržljivost | σ·0.5 + C·0.3 + ¬·0.2 |

---

## 6. 4 Mithjos dinamike (Z·J·E·N) — živi vektor duše

| Simbol | Pomen | Formula |
|---|---|---|
| **Z** | zavest | C·✡ + ∇·0.3 |
| **J** | ego-relacija | ∇·S + 0.2 |
| **E** | etični proces | ✡·P + 0.1 |
| **N** | paradoks / "Ne" | ¬·∆ + 0.1 |

---

## 7. Bojni faktorji (sposobnosti + moči → mehanika)

- **Laser damage** (škoda) = STR·0.05 + fizicna·2 + stopnja-laserja
- **Laser range** (domet) = 300 + INT·2 + stopnja-dometa
- **Devour damage** (škoda) = STR·0.04 + dusevna·2 + stopnja
- **Devour window** (okno) = 0.25 + WIS·0.003 + stopnja
- **Speed** (hitrost) = 220 + DEX·1.5 + stopnja
- **Reflex** (refleks) = (DEX + WIS) / 2
- **Aura** = (CHA + LUK) / 2

---

## 8. Ego** (0–1) — zavest igralca

Poveča vse statuse: efektivno = osnova × (1 + ego × 0.3).
- Izvirna duša: ego = 1.0
- Rezerve: ego = 0.0
- Inkarnirana: ego = 0.8

---

## 9. Zgodba, lobanje, modifikacije, nadgradnje

- **story_lines / fragments_touched** — pripoved duše (imenenčna plast).
- **skulls** — število smrti.
- **modifications** — mutacije / nadgradnje / blagoslovi / prekletstva (vsaka:
  tip, ime, stat, vrednost, trajna).
- **upgrade_points + 5 linearnih nadgradenj** — škoda/domet laserja,
  okno/izbruh devourja, hitrost.

---

## Povzetek povezav (kako se vse povezuje)

Genom (∇¬∆✡τσ C-N-P-S) → izpelje **sposobnosti** (STR..LUK) → izpelje **enačbo**
(psi) → in **moči** (8-škatla) ter **mithjos** (Z·J·E·N) berejo iste gene.
Sposobnosti + moči nato hranijo **bojne faktorje**. Karton je šiv, kjer se pripne
sistema reakcije/namena: operaterski geni (∇¬∆✡) so, kako duša *oblikuje reakcije*,
in mithjos (zavest / relacija / etika / paradoks) je *gorivo*, ki ga naraščajoča
veriga (MOLK→AKCIJA) pretvori v namen.

---

## Cilji gradnje Reakcija + Namen (naslednje)

- **Oblikovanje reakcije:** resonanca dejanja bere polja genoma (∇¬∆✡τσ kot
  operatorje besede) in psi kot nosilec-kakovost — ∅stavek `Sᵢ = α₁⊕α₂⊕...` preslika
  vsak α na ∇¬∆✡.
- **Reakcija:** odmev/validator spreminja mithjos (Z·J·E·N) in moči glede na to,
  kako je dejanje pristalo.
- **Gorivo namena:** naraščajoča veriga napreduje, ko mithjos/moči/psi dosežejo
  pragove — lastnosti na tem kartonu so tisto, kar reakcije hranijo in kar lestev
  namena bere.