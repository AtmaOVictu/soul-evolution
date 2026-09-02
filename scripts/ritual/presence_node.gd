# presence_node.gd — The faint thing that appears in the void
#
# CL-033: Before the question, something must appear.
# The player must NOTICE it. This is the ritual ground.
#
# A PresenceNode is a barely-visible pulse in the void. It breathes slowly.
# It does not announce itself. The player must find it with their attention.
#
# When the player clicks on or near it, it is "noticed":
#   - It brightens briefly (a flash of recognition)
#   - It emits presence_noticed
#   - It fades, leaving a trace position
#
# The trace position becomes the seed for the first distinction.
# The world begins not from the player's click, but from what they noticed.
#
# Ontological grounding:
#   ∅ → faint ∆ : the void trembles before distinction
#   "Preverba je tresenje" — verification is trembling
#   The player's attention is the first ontological operator.

extends Node2D

signal presence_noticed(position: Vector2)

enum Phase {
  DORMANT,     # Not yet visible — waiting to be activated
  PULSING,     # Faint pulse, barely visible, waiting to be noticed
  NOTICED,     # Player clicked on it — brightening flash
  FADING,      # Brightness fading, leaving trace
  GONE,        # Fully faded, removed from scene
}

var phase: Phase = Phase.DORMANT
var _breath_time: float = 0.0
var _pulse_position: Vector2 = Vector2.ZERO
var _pulse_radius: float = 30.0  # detection radius
var _notice_flash: float = 0.0   # 0..1, brightens when noticed
var _alpha: float = 0.0
var _fade_speed: float = 0.5

# Color: very faint blue-white, like starlight through fog
var _color: Color = Color(0.5, 0.6, 0.85, 0.0)

func _ready() -> void:
  # Start invisible
  _alpha = 0.0
  _color.a = 0.0

func activate(pos: Vector2) -> void:
  _pulse_position = pos
  position = pos
  phase = Phase.PULSING
  
  # Fade in slowly — the presence emerges, not appears
  var tween := create_tween()
  tween.tween_property(self, "_alpha", 0.15, 1.5)
  tween.set_trans(Tween.TRANS_SINE)
  tween.set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
  _breath_time += delta
  
  match phase:
    Phase.DORMANT:
      return
    
    Phase.PULSING:
      # Slow breathing — barely visible
      var breath := sin(_breath_time * 0.8) * 0.5 + 0.5  # 0..1
      _color.a = _alpha * (0.4 + breath * 0.6)
      queue_redraw()
    
    Phase.NOTICED:
      # Flash bright, then begin fading
      _notice_flash = lerpf(_notice_flash, 1.0, delta * 8.0)
      _color.a = lerpf(0.15, 0.9, _notice_flash)
      
      if _notice_flash > 0.95:
        phase = Phase.FADING
      
      queue_redraw()
    
    Phase.FADING:
      _notice_flash = lerpf(_notice_flash, 0.0, delta * _fade_speed)
      _color.a = _notice_flash * 0.5
      
      if _color.a < 0.01:
        phase = Phase.GONE
        _color.a = 0.0
        set_process(false)
        # Don't queue_free — leave the trace position accessible
        visible = false
      
      queue_redraw()

func _draw() -> void:
  if phase == Phase.DORMANT or phase == Phase.GONE:
    return
  
  var breath := sin(_breath_time * 0.8) * 0.3 + 0.7
  
  # Outer halo — very faint
  var halo_r := _pulse_radius * (1.5 + breath * 0.3)
  draw_circle(Vector2.ZERO, halo_r, Color(_color.r, _color.g, _color.b, _color.a * 0.15))
  
  # Inner glow
  var glow_r := _pulse_radius * 0.5 * (1.0 + breath * 0.2)
  draw_circle(Vector2.ZERO, glow_r, Color(_color.r, _color.g, _color.b, _color.a * 0.4))
  
  # Core — tiny, like a distant star
  if phase == Phase.PULSING:
    draw_circle(Vector2.ZERO, 2.0, Color(_color.r, _color.g, _color.b, _color.a))
  elif phase == Phase.NOTICED or phase == Phase.FADING:
    # When noticed, draw a brief ring expanding outward
    if _notice_flash > 0.1:
      var ring_r := _pulse_radius * (1.0 + (1.0 - _notice_flash) * 2.0)
      draw_arc(Vector2.ZERO, ring_r, 0, TAU, 32,
        Color(_color.r, _color.g, _color.b, _notice_flash * 0.6), 2.0)

func try_notice(click_pos: Vector2) -> bool:
  if phase != Phase.PULSING:
    return false
  
  # Check if click is within detection radius
  var dist := click_pos.distance_to(_pulse_position)
  if dist < _pulse_radius * 1.5:
    phase = Phase.NOTICED
    presence_noticed.emit(_pulse_position)
    return true
  
  return false

func get_trace_position() -> Vector2:
  return _pulse_position

func is_gone() -> bool:
  return phase == Phase.GONE

# Setter for tween
func _set_alpha(value: float) -> void:
  _alpha = value
