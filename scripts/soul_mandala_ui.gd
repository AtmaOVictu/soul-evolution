extends Control
## The Genome Mandala UI — hosts the interactive mandala next to a readout
## panel. Click a mandala segment -> the readout shows the attribute's name,
## its % value, and what it converts into (its visible use). Coherent with the
## canon's "the soul is what it is" and the genome's real conversion paths.

var genome: RefCounted = null

var mandala: Control = null
var title_label: Label
var value_label: Label
var detail_label: Label


func _ready() -> void:
	_build_panel()


func _build_panel() -> void:
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 20)
	add_child(hbox)

	mandala = preload("res://scripts/soul_mandala.gd").new()
	mandala.custom_minimum_size = Vector2(360, 360)
	mandala.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mandala.segment_selected.connect(_on_segment)
	hbox.add_child(mandala)

	var readout := VBoxContainer.new()
	readout.custom_minimum_size = Vector2(260, 0)
	readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(readout)

	title_label = Label.new()
	title_label.text = L.t("mandala_hint")
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	readout.add_child(title_label)

	value_label = Label.new()
	value_label.text = ""
	value_label.add_theme_font_size_override("font_size", 30)
	value_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	readout.add_child(value_label)

	detail_label = Label.new()
	detail_label.text = ""
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_label.add_theme_font_size_override("font_size", 14)
	detail_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	readout.add_child(detail_label)


func set_genome(g: RefCounted) -> void:
	genome = g
	if mandala:
		mandala.set_genome(g)


func _on_segment(name: String, value: float, detail: String) -> void:
	title_label.text = "%s  —  %s" % [L.tr("mandala_value"), name]
	value_label.text = "%.0f%%" % value
	detail_label.text = detail