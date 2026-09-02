# CL-032 Setup Guide — One Required Manual Step

## Step 1: Register the Events Autoload

In Godot Editor:
1. Open Project -> Project Settings
2. Go to the Autoload tab
3. Add a new autoload:
   - Path: `res://scripts/ritual/events.gd`
   - Name: `Events`
   - Type: Singleton (check Enabled)
4. Save

This is the ONLY manual step. Everything else is automatic.

## Step 2: Open the Ritual Scene

Open `scenes/ritual_loop.tscn` in the Godot editor.

## Step 3: Run

Press F6 (Run Current Scene).

You should see:
1. A dark void (breathing shader background)
2. The question "What is different here?" fading in with a typewriter effect
3. Click anywhere -> a glowing dot appears, kappa bar fills slightly,
   a consequence card slides in from the right
4. Click again -> a second dot, a boundary line between them,
   consequence card updates to show "A boundary exists"
5. Click the card or press Space -> card slides away,
   next question "Where is this true?" appears
6. The cycle repeats

## Troubleshooting

- **"Events" not found error:** You did not register the autoload. See Step 1.
- **Black screen, no question:** The FSM starts in VOID state. Add a call to 
  `start_ritual()` — either add a Button, or call it in _ready of the scene root.
  Simplest: add `Events.ritual_state_changed.emit(&"QUESTION")` in the scene root script.
  OR: the ritual_state_machine.gd already connects signals, but you need to 
  trigger the first transition. Add this to a root script on RitualLoop:

```gdscript
extends Control
func _ready():
    # Start the ritual after a brief delay for the void to settle
    await get_tree().create_timer(0.5).timeout
    $StateMachine.start_ritual()
```

## File Map

```
scripts/ritual/
  events.gd                    # Event Bus autoload (register this!)
  ritual_state_machine.gd      # FSM spine
  question_prompt.gd           # Question RichTextLabel
  consequence_card.gd          # Consequence Panel
  clarity_bar.gd               # Kappa ProgressBar
  distinction_field_ritual.gd  # Click handler -> distinction events

scenes/
  ritual_loop.tscn             # Integrated scene

docs/
  CL-032.md                    # Feature documentation
  CL-032-setup.md              # This file
```