# void_reactive_controller.gd — Feeds distinction positions to the void shader
#
# The void shader needs to know where distinctions are. This controller
# reads the distinction registry each frame and uploads positions + clarities
# to the shader material. The void then pools light around distinctions.
#
# Attach to the VoidBackground ColorRect (same node that has the shader material).

extends ColorRect

const MAX_DISTINCTIONS := 16

@onready var _material: ShaderMaterial = material

func _ready() -> void:
	Events.local_clarity_changed.connect(_on_clarity_changed)
	Events.distinction_spawned.connect(_on_distinction_spawned)
	
	# Initialize shader arrays
	var positions: PackedVector2Array = []
	var clarities: PackedFloat32Array = []
	for i in MAX_DISTINCTIONS:
		positions.append(Vector2(0.5, 0.5))
		clarities.append(0.0)
	_material.set_shader_parameter("distinction_positions", positions)
	_material.set_shader_parameter("distinction_clarities", clarities)
	_material.set_shader_parameter("distinction_count", 0)

func _process(_delta: float) -> void:
	_update_shader()

func _update_shader() -> void:
	var distinctions := Events.get_all_distinctions()
	var count := mini(distinctions.size(), MAX_DISTINCTIONS)
	
	var positions: PackedVector2Array = []
	var clarities: PackedFloat32Array = []
	
	for i in count:
		var d := distinctions[i] as Node2D
		if not is_instance_valid(d):
			positions.append(Vector2(0.5, 0.5))
			clarities.append(0.0)
			continue
		
		# Convert world position to normalized screen UV
		var screen_pos := d.global_position / get_viewport_rect().size
		positions.append(Vector2(screen_pos.x, screen_pos.y))
		clarities.append(d.local_clarity)
	
	# Fill remaining slots
	for i in range(count, MAX_DISTINCTIONS):
		positions.append(Vector2(0.5, 0.5))
		clarities.append(0.0)
	
	_material.set_shader_parameter("distinction_positions", positions)
	_material.set_shader_parameter("distinction_clarities", clarities)
	_material.set_shader_parameter("distinction_count", count)

func _on_clarity_changed(_node: Node, _new_value: float, _delta: float) -> void:
	_update_shader()  # immediate update on clarity change

func _on_distinction_spawned(_node: Node2D) -> void:
	_update_shader()