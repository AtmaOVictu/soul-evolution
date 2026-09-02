# boundary_node.gd — The relation between two distinctions
#
# A boundary is not drawn by the player. It appears as a consequence
# of two distinctions existing. The world produces it.
#
# The boundary has its own clarity — the average of its two endpoints
# plus a bonus for being a bounded pair. It pulses, thickens, and
# eventually solidifies like the distinctions it connects.

extends Line2D

var endpoint_a: Node2D = null
var endpoint_b: Node2D = null
var local_clarity: float = 0.0
var is_solid: bool = false

var _breath_time: float = 0.0

signal boundary_formed(boundary: Line2D)
signal boundary_solidified(boundary: Line2D)

func setup(a: Node2D, b: Node2D) -> void:
	endpoint_a = a
	end_a = a.position
	end_b = b.position
	
	# Connect to endpoint clarity changes
	a.clarity_changed.connect(_on_endpoint_clarity_changed)
	b.clarity_changed.connect(_on_endpoint_clarity_changed)
	
	# Initial clarity = average of endpoints + bonus for pairing
	_update_clarity()
	
	# Visual defaults
	width = 2.0
	default_color = Color(0.4, 0.5, 0.8, 0.4)
	
	# Animate appearance
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	tween.tween_callback(func(): boundary_formed.emit(self))

func _process(delta: float) -> void:
	if is_solid:
		return
	
	_breath_time += delta
	
	# Follow endpoints if they move (future: draggable distinctions)
	if endpoint_a and endpoint_b:
		points[0] = endpoint_a.position
		points[1] = endpoint_b.position
	
	# Pulse width and alpha with clarity
	var pulse := sin(_breath_time * 1.5) * 0.15
	width = 1.5 + local_clarity * 3.0
	default_color.a = 0.3 + local_clarity * 0.4 + pulse
	
	# Solidify when both endpoints are witnessed
	if endpoint_a and endpoint_b:
		if endpoint_a.is_witnessed and endpoint_b.is_witnessed:
			_solidify()

func _update_clarity() -> void:
	if not endpoint_a or not endpoint_b:
		return
	var avg := (endpoint_a.local_clarity + endpoint_b.local_clarity) / 2.0
	var old := local_clarity
	local_clarity = clampf(avg + 0.05, 0.0, 1.0)  # pair bonus
	if old != local_clarity:
		Events.local_clarity_changed.emit(self, local_clarity, local_clarity - old)

func _on_endpoint_clarity_changed(_node: Node2D, _new_value: float) -> void:
	_update_clarity()

func _solidify() -> void:
	if is_solid:
		return
	is_solid = true
	set_process(false)
	width = 2.0 + local_clarity * 2.0
	default_color.a = 0.7
	boundary_solidified.emit(self)