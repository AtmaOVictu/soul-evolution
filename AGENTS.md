# Soul Evolution — AI Agent Instructions

This project is a Godot game with GDScript and no separate build system. Use the files below to understand the core architecture and the key gameplay intent before making code changes.

## Key project facts

- Engine: Godot 4.7, `project.godot`
- Main scene: `res://scenes/main.tscn`
- Primary controller: `scripts/main.gd`
- Player soul: `scripts/soul.gd`
- Game logic is mostly in GDScript under `scripts/`
- Design notes and gameplay theme are in `DESIGN.md`

## What this game is about

- The game simulates a conflict between two polarities:
  - White soul = electron / matter
  - Black soul = positron / antimatter
- When they meet, they annihilate and release color/substance
- `world_color` is the primary global progression mechanic
- The game is intentionally about creation through conflict, not a standard win condition

## Important code responsibilities

- `scripts/main.gd`
  - game state and UI flow
  - main menu, polarity choice, HUD, pause, narration
  - battle system, army management, and world saturation
  - auto-test entry point via `OS.get_cmdline_args()` and `--auto`
- `scripts/soul.gd`
  - player soul movement, abilities, life, and color-based mechanics
  - white beam vs black force field
- `scripts/hex_grid.gd`
  - hex maze terrain and room/corridor structure
- `scripts/character_sheet.gd`
  - avatar stats and character/ego display
- `scripts/soul_genome.gd`
  - soul attributes and derived values such as speed, capacity, and damage
- `scripts/soul_stream.gd`
  - incarnation flow and related mechanics
- `shaders/void.gdshader`
  - background desaturation / color saturation visual effect

## Development guidance

- Do not assume a standard build/test pipeline; run or inspect in Godot Editor if possible
- Preserve the conflict/color narrative when changing core systems such as annihilation, `world_color`, `substance`, and `pandora_opened`
- Keep gameplay semantics in mind: white is creation/light, black is destruction/force
- If you need more context on design intent, refer to `DESIGN.md`

## How to run or test

- Open the project in Godot and run `scenes/main.tscn`
- For automated validation, the game checks for `--auto` in command-line args and prints debug state to the console

## Useful references

- `DESIGN.md` — high-level game goals, identity, and current state
- `project.godot` — project settings and main scene declaration
