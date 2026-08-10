extends Control
## The Grand Council modal — the last survivors' forced choice.
## (canon/00-mythos.md act 3; CRITICAL_BRIEF.md §3/§8.) Built entirely in
## GDScript, no .tscn, matching vault_machine_ui.gd/character_sheet.gd. This
## file holds no choice logic of its own — it only calls back into
## main_ref._resolve_council(), same reach-in pattern character_sheet.gd
## uses for main_ref, per "the game does not give knowledge lightly": no
## explanation of what domination/split actually cost is shown here.

var main_ref: Node = null


func _ready() -> void:
	_build_panel()
	visible = false


func _build_panel() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 260)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = L.t("council_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = L.t("council_sub")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	sub.custom_minimum_size = Vector2(360, 0)
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.55, 0.55, 0.58))
	vbox.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)

	var domination_btn := Button.new()
	domination_btn.text = L.t("council_domination")
	domination_btn.custom_minimum_size = Vector2(320, 46)
	domination_btn.add_theme_font_size_override("font_size", 18)
	domination_btn.pressed.connect(_on_domination_pressed)
	vbox.add_child(domination_btn)

	var split_btn := Button.new()
	split_btn.text = L.t("council_split")
	split_btn.custom_minimum_size = Vector2(320, 46)
	split_btn.add_theme_font_size_override("font_size", 18)
	split_btn.pressed.connect(_on_split_pressed)
	vbox.add_child(split_btn)


func _on_domination_pressed() -> void:
	if main_ref and main_ref.has_method("_resolve_council"):
		main_ref._resolve_council("domination")


func _on_split_pressed() -> void:
	if main_ref and main_ref.has_method("_resolve_council"):
		main_ref._resolve_council("split")
