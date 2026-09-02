# agent_routing_deck.gd — Make agents executable (CL-043)
#
# The Agent Routing Deck lets the player route a RES Material Card
# to one of three agents. Each agent transforms the material differently:
#
#   MONSTER (⊗) — carrier of breaks and unexpected leaps
#     Input: RES card → Output: anomaly injection (adds noise, breaks patterns)
#     Use when: the pattern is too stable, needs disruption
#
#   ADVANCED (⟡) — conscious access to higher axiom layers
#     Input: RES card → Output: axiom alignment (increases coherence κ)
#     Use when: the pattern needs deeper grounding
#
#   SHADOW (¬) — carrier of hidden truths, defined through difference
#     Input: RES card → Output: remnant trace (reveals what was unseen)
#     Use when: something is missing but you don't know what
#
# The deck appears at the bottom of the screen after SEAL.
# The player drags a RES card to one of three slots.
# The agent processes it and produces a consequence.
#
# Ontological grounding:
#   Agent metaphunction: möglichkeit (possible), möglich (networked), fähig (capable)
#   Activation: Monster oscillates → activates Advanced → activates Shadow.
#   Agents model BEING, not behavior.

extends Control

signal agent_routed(agent_type: StringName, res_card: Node2D, result: Dictionary)

const DistinctionNode = preload("res://scripts/ritual/distinction_node.gd")
const RESMaterialCard = preload("res://scripts/ritual/res_material_card.gd")

enum AgentType {
  MONSTER,
  ADVANCED,
  SHADOW,
}

const AGENT_NAMES := {
  AgentType.MONSTER: "Monster",
  AgentType.ADVANCED: "Advanced",
  AgentType.SHADOW: "Shadow",
}

const AGENT_GLYPHS := {
  AgentType.MONSTER: "⊗",
  AgentType.ADVANCED: "⟡",
  AgentType.SHADOW: "¬",
}

const AGENT_COLORS := {
  AgentType.MONSTER: Color(0.7, 0.3, 0.3, 0.8),
  AgentType.ADVANCED: Color(0.3, 0.6, 0.8, 0.8),
  AgentType.SHADOW: Color(0.5, 0.4, 0.7, 0.8),
}

const AGENT_DESCRIPTIONS := {
  AgentType.MONSTER: "Carrier of breaks. Injects anomaly. Disrupts stable patterns.",
  AgentType.ADVANCED: "Conscious access. Aligns axioms. Deepens coherence.",
  AgentType.SHADOW: "Carrier of hidden truths. Reveals what was unseen through difference.",
}

var _is_active: bool = false
var _breath_time: float = 0.0
var _slots: Dictionary = {}  # AgentType -> Rect2
var _hovered_slot: int = -1
var _dragged_card: Node2D = null
var _drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
  visible = false
  mouse_filter = Control.MOUSE_FILTER_STOP

func activate() -> void:
  _is_active = true
  visible = true
  
  # Compute slot positions
  var size_rect := get_rect()
  var slot_w := 100.0
  var slot_h := 80.0
  var gap := 20.0
  var total_w := slot_w * 3 + gap * 2
  var start_x := (size_rect.size.x - total_w) / 2
  
  _slots[AgentType.MONSTER] = Rect2(start_x, 10, slot_w, slot_h)
  _slots[AgentType.ADVANCED] = Rect2(start_x + slot_w + gap, 10, slot_w, slot_h)
  _slots[AgentType.SHADOW] = Rect2(start_x + (slot_w + gap) * 2, 10, slot_w, slot_h)
  
  modulate.a = 0.0
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 1.0, 0.4)

func deactivate() -> void:
  _is_active = false
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 0.0, 0.3)
  tween.tween_callback(func(): visible = false)

func _process(delta: float) -> void:
  _breath_time += delta
  queue_redraw()

func _draw() -> void:
  if not _is_active:
    return
  
  var breath := sin(_breath_time * 0.5) * 0.1 + 0.9
  
  # Draw title
  draw_string(get_theme_default_font(), Vector2(10, -2),
    "Route to Agent:", 0, 200, 12, Color(0.6, 0.7, 0.9, 0.5))
  
  # Draw each slot
  for agent_type in [AgentType.MONSTER, AgentType.ADVANCED, AgentType.SHADOW]:
    var rect: Rect2 = _slots[agent_type]
    var is_hovered := (_hovered_slot == agent_type)
    var color := AGENT_COLORS[agent_type]
    var alpha := 0.3 * breath if not is_hovered else 0.5 * breath
    
    # Slot background
    draw_rect(rect, Color(color.r, color.g, color.b, alpha), true)
    draw_rect(rect, Color(color.r, color.g, color.b, 0.6), false, 2.0)
    
    # Agent glyph
    draw_string(get_theme_default_font(), 
      rect.position + Vector2(rect.size.x / 2 - 8, 25),
      AGENT_GLYPHS[agent_type], 0, -1, 20,
      Color(color.r * 1.3, color.g * 1.3, color.b * 1.3, 0.8 * breath))
    
    # Agent name
    draw_string(get_theme_default_font(),
      rect.position + Vector2(10, 45),
      AGENT_NAMES[agent_type], 0, rect.size.x - 20, 9,
      Color(0.7, 0.8, 0.9, 0.5 * breath))

func _gui_input(event: InputEvent) -> void:
  if not _is_active:
    return
  
  if event is InputEventMouseMotion:
    var pos := event.position
    _hovered_slot = -1
    for agent_type in _slots:
      if _slots[agent_type].has_point(pos):
        _hovered_slot = agent_type
        break
    
    if _dragged_card and is_instance_valid(_dragged_card):
      _dragged_card.position = pos + _drag_offset
  
  elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    # Check if clicking on a RES card in the layer
    var layer := get_parent().get_node_or_null("DistinctionLayer")
    if layer:
      for child in layer.get_children():
        if child.get_script() == RESMaterialCard:
          if event.position.distance_to(child.position) < 50.0:
            _dragged_card = child
            _drag_offset = child.position - event.position
            return
  
  elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    if _dragged_card and is_instance_valid(_dragged_card):
      # Check if dropped on a slot
      var dropped_pos := _dragged_card.position
      for agent_type in _slots:
        if _slots[agent_type].has_point(dropped_pos):
          _route_to_agent(agent_type, _dragged_card)
          break
      
      _dragged_card = null

func _route_to_agent(agent_type: int, res_card: Node2D) -> void:
  var result := {}
  
  match agent_type:
    AgentType.MONSTER:
      result = {
        "type": "anomaly",
        "description": "The Monster breaks the pattern. Noise enters. Something shifts.",
        "clarity_delta": -0.05,
        "effect": "disruption"
      }
    AgentType.ADVANCED:
      result = {
        "type": "alignment",
        "description": "The Advanced aligns axioms. Coherence deepens. κ rises.",
        "clarity_delta": 0.10,
        "effect": "grounding"
      }
    AgentType.SHADOW:
      result = {
        "type": "remnant",
        "description": "The Shadow reveals what was unseen. A trace appears.",
        "clarity_delta": 0.0,
        "effect": "revelation"
      }
  
  agent_routed.emit(StringName(AGENT_NAMES[agent_type]), res_card, result)
  
  # Show consequence
  Events.consequence_shown.emit(
    "%s routed" % AGENT_NAMES[agent_type],
    result["description"],
    "κ | Effect: %s" % result["effect"],
    "%.2f (%s)" % [Events.get_aggregate_clarity(), result["type"]]
  )
