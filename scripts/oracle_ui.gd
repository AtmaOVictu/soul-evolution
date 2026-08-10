extends Control
## The Oracle of the Many Windows — the interactive window for the upgradeable
## OracleAsset. Shows the fated reading (a Blender sigil, the verdict, the
## register, a canon phrase) and lets the player CONSULT (spend dust) and
## UPGRADE (spend dust to raise its sight-tier). Built coherently on the
## existing art (sigils, portraits) and economy (dust, held on main_ref).

var main_ref: Node = null
var oracle: RefCounted = null

var consult_button: Button
var upgrade_button: Button
var status_label: Label
var insight_label: Label
var reading_label: Label
var sigil_rect: TextureRect


func _ready() -> void:
	_build_panel()
	visible = false


func _build_panel() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.07, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var sheet := PanelContainer.new()
	sheet.custom_minimum_size = Vector2(420, 480)
	center.add_child(sheet)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	sheet.add_child(vbox)

	var title := Label.new()
	title.text = L.t("oracle_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	vbox.add_child(title)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	vbox.add_child(status_label)

	sigil_rect = TextureRect.new()
	sigil_rect.custom_minimum_size = Vector2(120, 120)
	sigil_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sigil_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sigil_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(sigil_rect)

	reading_label = Label.new()
	reading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reading_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	reading_label.add_theme_font_size_override("font_size", 14)
	reading_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(reading_label)

	insight_label = Label.new()
	insight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	insight_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	insight_label.add_theme_font_size_override("font_size", 13)
	insight_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.4))
	vbox.add_child(insight_label)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)

	consult_button = Button.new()
	consult_button.custom_minimum_size = Vector2(360, 44)
	consult_button.add_theme_font_size_override("font_size", 18)
	consult_button.pressed.connect(_on_consult)
	vbox.add_child(consult_button)

	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(360, 44)
	upgrade_button.add_theme_font_size_override("font_size", 16)
	upgrade_button.pressed.connect(_on_upgrade)
	vbox.add_child(upgrade_button)

	var back_button := Button.new()
	back_button.text = L.t("menu_back")
	back_button.flat = true
	back_button.pressed.connect(func(): visible = false)
	vbox.add_child(back_button)

	_refresh()


func _get_dust() -> int:
	if main_ref and "dust" in main_ref:
		return main_ref.dust
	return 0


func _spend_dust(amount: int) -> void:
	if main_ref and "dust" in main_ref:
		main_ref.dust -= amount


func _on_consult() -> void:
	if not oracle:
		return
	var r: Dictionary = oracle.consult(_get_dust())
	if r["ok"]:
		_spend_dust(oracle.consult_cost())
		_show_reading(r)
	else:
		reading_label.text = L.t("oracle_no_dust")
	_refresh()


func _on_upgrade() -> void:
	if not oracle:
		return
	if oracle.upgrade(_get_dust()):
		_spend_dust(oracle.upgrade_cost())
		narrate(L.t("oracle_upgraded"))
	_refresh()


func _show_reading(r: Dictionary) -> void:
	var sigil_path := "res://assets/%s.png" % r["sigil"]
	if ResourceLoader.exists(sigil_path):
		sigil_rect.texture = load(sigil_path)
		sigil_rect.visible = true
	reading_label.text = L.t("oracle_reading") % [r["operator"], r["verdict"], r["register"]]
	reading_label.text += "\n\"%s\"" % r["phrase"]
	insight_label.text = "bias: %s" % oracle.fate_insight()


func narrate(_t: String) -> void:
	# The oracle surfaces its own word; the narrator's voice is main's job.
	pass


func _refresh() -> void:
	if not oracle:
		return
	status_label.text = L.t("oracle_status") % [oracle.tier, oracle.consultations, oracle.dust_spent]
	consult_button.text = L.t("oracle_consult") % oracle.consult_cost()
	if oracle.is_maxed():
		upgrade_button.text = L.t("oracle_maxed")
		upgrade_button.disabled = true
	else:
		upgrade_button.text = L.t("oracle_upgrade") % oracle.upgrade_cost()
		upgrade_button.disabled = false
	if oracle.consultations > 0 and insight_label.text.is_empty():
		insight_label.text = oracle.fate_insight()