extends Window
## THE AUTONOMOUS CHARACTER WINDOW — the character sheet as its own site/window,
## not a child of the battle HUD. It hosts the full character sheet + the
## animated genome mandala, and is the SOURCE from which other needs are
## DERIVED/DEVISED: the Oracle, the Gallery, the Vault, the Battle — each opened
## from here as its own window. This is the "many windows of the plane" hub.

var main_ref: Node = null
var sheet: Control = null
var _nav_row: HBoxContainer = null


func _ready() -> void:
	title = L.t("sheet_window_title")
	transient = false
	exclusive = false
	close_requested.connect(_on_close)
	_build_window()


func _build_window() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	# Nav row — the needs derived from this window.
	_nav_row = HBoxContainer.new()
	_nav_row.add_theme_constant_override("separation", 8)
	root.add_child(_nav_row)
	_add_nav(L.t("nav_oracle"), _open_oracle)
	_add_nav(L.t("nav_gallery"), _open_gallery)
	_add_nav(L.t("nav_vault"), _open_vault)
	_add_nav(L.t("nav_battle"), _open_battle)

	# The full character sheet as the window's body.
	sheet = preload("res://scripts/character_sheet.gd").new()
	sheet.name = "CharacterSheet"
	sheet.main_ref = main_ref
	sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sheet)


func _add_nav(text: String, handler: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.flat = true
	btn.pressed.connect(handler)
	_nav_row.add_child(btn)


func set_genome(g: RefCounted) -> void:
	if sheet:
		sheet.set_genome(g)


func _open_oracle() -> void:
	if main_ref and main_ref.has_method("_open_oracle_window"):
		main_ref._open_oracle_window()


func _open_gallery() -> void:
	if main_ref and main_ref.has_method("_open_gallery_window"):
		main_ref._open_gallery_window()


func _open_vault() -> void:
	if main_ref and main_ref.has_method("_open_vault_window"):
		main_ref._open_vault_window()


func _open_battle() -> void:
	if main_ref and main_ref.has_method("_open_battle_window"):
		main_ref._open_battle_window()


func _on_close() -> void:
	hide()
	if main_ref and main_ref.has_method("_character_window_closed"):
		main_ref._character_window_closed()