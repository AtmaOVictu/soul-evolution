extends Control
## Character sheet — D&D-style panel showing a soul's genome and abilities.
## Press TAB to open/close. Structured around canon debate-log #033's
## Absolute/Immanence two-level model (every entity has an opaque-math layer
## and an embodied-meaning layer) — see render_soul() below. Renders either
## the currently active, playable soul, or a read-only vault-stored one,
## through the same template ("shared frame, honest depth").

enum Mode { ACTIVE, VAULT_VIEW }

const SacredGeometryScript := preload("res://scripts/sacred_geometry.gd")

var genome: RefCounted  # kept for compatibility with direct external reads; mirrors _active_genome in ACTIVE mode
var mode: int = Mode.ACTIVE
var _active_genome: RefCounted = null

# World-level state (dust/balance/vault) lives on main.gd, not the genome —
# it's not soul-intrinsic. Read via duck-typed access, same pattern
# hex_grid.gd already uses for world_color/color_balance.
var main_ref: Node = null

var sheet: PanelContainer
var back_button: Button
var menu_button: Button
var provenance_label: Label
var title_label: Label
var polar_label: Label
var ability_vals: Dictionary = {}
var pool_labels: Dictionary = {}
var skull_glyph_label: Label
var skull_abs_label: Label
var psi_val_label: Label
var story_label: Label
var power_vals: Dictionary = {}
var mithjos_vals: Dictionary = {}
var upgrade_points_label: Label
var upgrade_list_label: Label
var dust_val_label: Label
var balance_val_label: Label
var vault_val_label: Label
var vault_grid: GridContainer
var mods_val_label: Label

var absolute_section: VBoxContainer
var immanence_section: VBoxContainer
var world_section: VBoxContainer

# Soul Vault "windows" — canon's per-element treasure-hoard art frame
# (canon/05-treasures.md:59-63, canon/00-mythos.md:95). Shell-only asset,
# same rule as the soul sprites (blender/generate_souls.py): loaded
# defensively since the Blender pipeline may not have been (re)run.
var _window_frame_tex: Texture2D = null
var _frame_stylebox: StyleBoxTexture = null
var _vault_grid_count: int = -1

# When opened from the main menu (no active battle), a "back to menu" button
# is shown instead of the TAB-style active-soul behaviour.
var from_menu: bool = false
var menu_return: Callable = Callable()


func _ready() -> void:
	_build_panel()
	visible = false
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	# TAB always reopens on the active soul, regardless of what was last
	# viewed in the vault gallery.
	if visible and _active_genome:
		mode = Mode.ACTIVE
		back_button.visible = false
		menu_button.visible = from_menu
		world_section.visible = true
		render_soul(_active_genome, {})
		_refresh_world()


func set_genome(g: RefCounted) -> void:
	_active_genome = g
	genome = g
	mode = Mode.ACTIVE
	back_button.visible = false
	world_section.visible = true
	render_soul(g, {})
	_refresh_world()


func _build_panel() -> void:
	var frame_path := "res://assets/window_frame.png"
	if ResourceLoader.exists(frame_path):
		_window_frame_tex = load(frame_path)

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.09, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	sheet = PanelContainer.new()
	sheet.custom_minimum_size = Vector2(520, 620)
	center.add_child(sheet)

	# Frame styling — same window_frame.png asset used at 40x40 in the vault
	# gallery (below), scaled up via 9-slice margins so the whole sheet reads
	# as one large "window" (canon/10-galaxy.md:37-45). Tint (modulate_color)
	# is set per-render in render_soul() — never baked, always live.
	_frame_stylebox = StyleBoxTexture.new()
	if _window_frame_tex:
		_frame_stylebox.texture = _window_frame_tex
		# 24 ~= PHI^2 * 9.17 -- already phi-aligned, left as-is (canon/01b-sacred-geometry.md).
		_frame_stylebox.texture_margin_left = 24
		_frame_stylebox.texture_margin_right = 24
		_frame_stylebox.texture_margin_top = 24
		_frame_stylebox.texture_margin_bottom = 24
		sheet.add_theme_stylebox_override("panel", _frame_stylebox)
	# else: no override — sheet falls back to the default theme panel style,
	# so the pipeline not having been run yet doesn't break the layout.

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sheet.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)  # 3.0 * PHI^0.5, rounded (canon/01b-sacred-geometry.md)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	back_button = Button.new()
	back_button.text = L.t("back_to_soul")
	back_button.flat = true
	back_button.visible = false
	back_button.pressed.connect(_on_back_pressed)
	vbox.add_child(back_button)

	menu_button = Button.new()
	menu_button.text = L.t("menu_back")
	menu_button.flat = true
	menu_button.visible = false
	menu_button.pressed.connect(_on_menu_return)
	vbox.add_child(menu_button)

	provenance_label = Label.new()
	provenance_label.add_theme_font_size_override("font_size", 12)
	provenance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	provenance_label.visible = false
	vbox.add_child(provenance_label)

	# --- IMMANENCE (embodied meaning: name, felt history, felt weight) ---
	immanence_section = VBoxContainer.new()
	immanence_section.add_theme_constant_override("separation", 4)  # 3.0 * PHI^0.5, rounded (canon/01b-sacred-geometry.md)
	vbox.add_child(immanence_section)
	_section_header(immanence_section, L.t("section_immanence"))

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	immanence_section.add_child(title_label)

	polar_label = Label.new()
	polar_label.add_theme_font_size_override("font_size", 14)
	polar_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	immanence_section.add_child(polar_label)

	skull_glyph_label = Label.new()
	skull_glyph_label.add_theme_font_size_override("font_size", 15)
	skull_glyph_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	immanence_section.add_child(skull_glyph_label)

	mods_val_label = Label.new()
	mods_val_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	mods_val_label.add_theme_font_size_override("font_size", 12)
	mods_val_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.65))
	immanence_section.add_child(mods_val_label)

	_section_header(immanence_section, L.t("section_story"))
	story_label = Label.new()
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	story_label.add_theme_font_size_override("font_size", 13)
	story_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.55))
	story_label.custom_minimum_size.y = 60
	immanence_section.add_child(story_label)

	_sep(vbox)

	# --- ABSOLUTE (opaque math: raw numbers, formulas, fixed legends) ---
	absolute_section = VBoxContainer.new()
	absolute_section.add_theme_constant_override("separation", 4)  # 3.0 * PHI^0.5, rounded (canon/01b-sacred-geometry.md)
	vbox.add_child(absolute_section)
	_section_header(absolute_section, L.t("section_absolute"))

	var names := ["STR", "STA", "INT", "WIS", "CHA", "DEX", "LUK"]
	for a_name in names:
		var row := HBoxContainer.new()
		absolute_section.add_child(row)
		var lbl := Label.new()
		lbl.text = "%-3s  %s" % [a_name, L.t(a_name)]
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", 15)
		val.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		row.add_child(val)
		ability_vals[a_name] = val

	# --- 8 Powers (THE BOX) ---
	_section_header(absolute_section, L.t("section_powers"))
	var pow_names := ["fizicna", "psiholoska", "custvena", "duhovna", "dusevna", "inteligenca", "gibljivost", "stamina"]
	for pname in pow_names:
		var row := HBoxContainer.new()
		absolute_section.add_child(row)
		var lbl := Label.new()
		lbl.text = "%-14s" % L.t("pow_" + pname)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", 13)
		val.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		row.add_child(val)
		power_vals[pname] = val

	# --- 4 Mithjos Dynamics ---
	_section_header(absolute_section, L.t("section_mithjos"))
	var mith_names := [["Z", "mith_Z"], ["J", "mith_J"], ["E", "mith_E"], ["N", "mith_N"]]
	for pair in mith_names:
		var row := HBoxContainer.new()
		absolute_section.add_child(row)
		var lbl := Label.new()
		lbl.text = "%s  %s" % [pair[0], L.t(pair[1])]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", 13)
		val.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		row.add_child(val)
		mithjos_vals[pair[0]] = val

	# --- Pools ---
	for pool_name in ["capacity", "reflex", "aura"]:
		var row := HBoxContainer.new()
		absolute_section.add_child(row)
		var lbl := Label.new()
		var icon := "♡" if pool_name == "capacity" else ("⟳" if pool_name == "reflex" else "✧")
		lbl.text = "%s %s" % [icon, L.t("pool_" + pool_name)]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", 14)
		row.add_child(val)
		pool_labels[pool_name] = val

	skull_abs_label = Label.new()
	skull_abs_label.add_theme_font_size_override("font_size", 14)
	skull_abs_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.6))
	absolute_section.add_child(skull_abs_label)

	_section_header(absolute_section, L.t("section_genome"))
	var gene_eq := Label.new()
	gene_eq.text = "Psi(x) = div_inf(pi(x)) / neg(neg(x)) + del*x * trace"
	gene_eq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gene_eq.add_theme_font_size_override("font_size", 13)
	gene_eq.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	absolute_section.add_child(gene_eq)

	psi_val_label = Label.new()
	psi_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	psi_val_label.add_theme_font_size_override("font_size", 12)
	psi_val_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	absolute_section.add_child(psi_val_label)

	upgrade_points_label = Label.new()
	upgrade_points_label.add_theme_font_size_override("font_size", 14)
	upgrade_points_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	absolute_section.add_child(upgrade_points_label)
	upgrade_list_label = Label.new()
	upgrade_list_label.add_theme_font_size_override("font_size", 12)
	upgrade_list_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	upgrade_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	absolute_section.add_child(upgrade_list_label)

	_sep(vbox)

	# --- WORLD (dust, color balance, vault) — not soul-intrinsic, active-soul only ---
	world_section = VBoxContainer.new()
	world_section.add_theme_constant_override("separation", 4)  # 3.0 * PHI^0.5, rounded (canon/01b-sacred-geometry.md)
	vbox.add_child(world_section)
	_section_header(world_section, L.t("section_world"))
	dust_val_label = _add_row(world_section, L.t("world_dust"))
	balance_val_label = _add_row(world_section, L.t("world_balance"))
	vault_val_label = _add_row(world_section, L.t("world_vault"))
	vault_grid = GridContainer.new()
	vault_grid.columns = 6
	vault_grid.add_theme_constant_override("h_separation", 4)
	vault_grid.add_theme_constant_override("v_separation", 4)
	world_section.add_child(vault_grid)


func _section_header(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	parent.add_child(lbl)


func _sep(parent: Control) -> void:
	parent.add_child(HSeparator.new())


func _add_row(parent: Control, label_text: String) -> Label:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var val := Label.new()
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	row.add_child(val)
	return val


## The one reusable rendering path — the actual "uniform character sheet"
## template. Populates the Absolute and Immanence sections from ANY
## SoulGenome (the currently active, playable soul, or a read-only
## vault-stored one) — never touches main_ref or world_section, which is
## the boundary that keeps this generic. `provenance` is only non-empty for
## a vault record ({"quality": ..., "date_acq": ...}); it describes the draw
## event, not the soul, so it renders in its own strip, never folded into
## either section.
func render_soul(g: RefCounted, provenance: Dictionary) -> void:
	if not g:
		return

	if provenance.is_empty():
		provenance_label.visible = false
	else:
		provenance_label.visible = true
		provenance_label.text = "%s · %s %s" % [
			String(provenance.get("quality", "")).to_upper(),
			L.t("drawn"),
			provenance.get("date_acq", "")
		]
		provenance_label.add_theme_color_override("font_color", _color_for_quality(provenance.get("quality", "")))

	# Frame tint: honest per context, never fabricated. A vault record is
	# tinted by its draw quality; a live soul has no "quality" of its own,
	# so it's tinted by its own polarity instead.
	if _frame_stylebox:
		if not provenance.is_empty():
			_frame_stylebox.modulate_color = _color_for_quality(provenance.get("quality", ""))
		else:
			_frame_stylebox.modulate_color = Color(0.85, 0.85, 0.9) if g.polarity == 0 else Color(0.4, 0.35, 0.5)

	# --- IMMANENCE ---
	title_label.text = "SOUL #%04d" % g.soul_id
	polar_label.text = "%s %s" % [
		g.get_symbol_text(),
		L.t("polar_white") if g.polarity == 0 else L.t("polar_black")
	]
	var skull_str := "☠ %s  " % L.t("skulls")
	for i in g.skulls:
		skull_str += "▓"
	for i in maxi(0, 10 - g.skulls):
		skull_str += "░"
	skull_glyph_label.text = skull_str
	if g.has_method("get_modification_summary"):
		mods_val_label.text = "%s: %s" % [L.t("mods"), g.get_modification_summary()]
	var txt := ""
	for line in g.story_lines:
		txt += "\"%s\"\n" % line
	for frag in g.fragments_touched:
		txt += "→ %s\n" % frag
	if txt.is_empty():
		txt = L.t("story_empty")
	story_label.text = txt

	# --- ABSOLUTE ---
	for key in ability_vals:
		ability_vals[key].text = str(g.get(key))
	pool_labels["capacity"].text = "%d / %d" % [g.capacity_current, g.capacity_max]
	pool_labels["reflex"].text = str(g.get_reflex())
	pool_labels["aura"].text = str(g.get_aura())
	skull_abs_label.text = "%s: %d" % [L.t("skulls_lower"), g.skulls]
	psi_val_label.text = "div %.2f  neg %.2f  del %.2f  trace %.2f  tau %.2f  sig %.2f  C %.2f  N %.2f  P %.2f  S %.2f  Psi=%.3f" % [
		g.divergence, g.negation, g.delta, g.trace,
		g.tau, g.sigma, g.carbon, g.nitrogen,
		g.phosphorus, g.sulfur, g.psi
	]
	power_vals["fizicna"].text = "%.2f" % g.pow_fizicna
	power_vals["psiholoska"].text = "%.2f" % g.pow_psiholoska
	power_vals["custvena"].text = "%.2f" % g.pow_custvena
	power_vals["duhovna"].text = "%.2f" % g.pow_duhovna
	power_vals["dusevna"].text = "%.2f" % g.pow_dusevna
	power_vals["inteligenca"].text = "%.2f" % g.pow_inteligenca
	power_vals["gibljivost"].text = "%.2f" % g.pow_gibljivost
	power_vals["stamina"].text = "%.2f" % g.pow_stamina_val
	mithjos_vals["Z"].text = "%.2f" % g.mithjos_Z
	mithjos_vals["J"].text = "%.2f" % g.mithjos_J
	mithjos_vals["E"].text = "%.2f" % g.mithjos_E
	mithjos_vals["N"].text = "%.2f" % g.mithjos_N
	upgrade_points_label.text = "⭐ %s: %d" % [L.t("upgrade_points"), g.upgrade_points]
	var ul := ""
	var cats := ["laser_dmg", "laser_rng", "devour_win", "devour_bst", "speed"]
	var lvls := [g.laser_damage_level, g.laser_range_level, g.devour_window_level, g.devour_burst_level, g.speed_level]
	for i in cats.size():
		ul += "  %s Lv.%d" % [g.get_upgrade_name(cats[i]), lvls[i]]
	upgrade_list_label.text = ul


## World-level state (dust/balance/vault summary/gallery) — active-soul only,
## deliberately outside render_soul()'s scope.
func _refresh_world() -> void:
	if not main_ref:
		return
	if "dust" in main_ref:
		dust_val_label.text = str(main_ref.dust)
	if "color_balance" in main_ref:
		var b: float = main_ref.color_balance
		var b_desc := L.t("balance_neutral")
		if b > 0.15:
			b_desc = L.t("balance_white")
		elif b < -0.15:
			b_desc = L.t("balance_black")
		balance_val_label.text = "%.2f (%s)" % [b, b_desc]
	if "soul_vault" in main_ref and main_ref.soul_vault:
		vault_val_label.text = main_ref.soul_vault.get_vault_summary()
		_refresh_vault_grid(main_ref.soul_vault.souls)


func _refresh() -> void:
	if mode == Mode.VAULT_VIEW:
		return  # static — a vault soul isn't taking damage in real time
	if not _active_genome:
		return
	genome = _active_genome
	render_soul(_active_genome, {})
	_refresh_world()


func _on_menu_return() -> void:
	from_menu = false
	visible = false
	if menu_return.is_valid():
		menu_return.call()


func _on_back_pressed() -> void:
	mode = Mode.ACTIVE
	genome = _active_genome
	back_button.visible = false
	world_section.visible = true
	if _active_genome:
		render_soul(_active_genome, {})
	_refresh_world()


func _on_vault_entry_pressed(rec: Dictionary) -> void:
	mode = Mode.VAULT_VIEW
	genome = rec.get("genome")
	world_section.visible = false
	back_button.visible = true
	render_soul(rec.get("genome"), {"quality": rec.get("quality", ""), "date_acq": rec.get("date_acq", "")})


## Vault "windows" — one framed/tinted, clickable entry per soul record held
## in the vault. Rebuilt only when the record count changes (this whole
## sheet is re-`_refresh()`'d every frame while visible, per main.gd)
## rather than every call, so an open sheet doesn't rebuild N controls
## 60x/sec. Clicking an entry opens it into the same render_soul() template
## the active soul uses (see _on_vault_entry_pressed above).
func _refresh_vault_grid(souls: Array) -> void:
	if not vault_grid:
		return
	if souls.size() == _vault_grid_count:
		return
	_vault_grid_count = souls.size()
	for child in vault_grid.get_children():
		child.queue_free()
	for rec in souls:
		var entry := Button.new()
		entry.custom_minimum_size = Vector2(40, 40)
		entry.flat = true
		entry.text = ""
		entry.pressed.connect(_on_vault_entry_pressed.bind(rec))
		vault_grid.add_child(entry)

		if _window_frame_tex:
			var tex_rect := TextureRect.new()
			tex_rect.texture = _window_frame_tex
			tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.modulate = _color_for_quality(rec.get("quality", ""))
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			entry.add_child(tex_rect)

		var glyph := Control.new()
		glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.draw.connect(_draw_vault_glyph.bind(glyph, rec))
		entry.add_child(glyph)

		# Blender-rendered soul portrait inside the window — real gallery art,
		# replacing the procedural placeholder. Picked deterministically from
		# the soul's genome + quality.
		var portrait_path := "res://assets/portrait_%s.png" % _portrait_for(rec)
		if ResourceLoader.exists(portrait_path):
			var portrait := TextureRect.new()
			portrait.texture = load(portrait_path)
			portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.modulate = _color_for_quality(rec.get("quality", ""))
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			entry.add_child(portrait)


## Deterministically pick a Blender soul-portrait for a vault record, from the
## soul's genome (psi + polarity) and quality. Same soul → same portrait.
func _portrait_for(rec: Dictionary) -> String:
	var portraits := ["sphere", "shard", "torus", "crystal", "ring", "twin", "hexstar",
		"drop", "spire", "orb", "facet", "veil"]
	var g = rec.get("genome")
	var seed := 0
	if g:
		seed = int(clampf(g.psi, 0.0, 1.0) * 100.0) + (g.polarity * 7)
	match rec.get("quality", ""):
		"good":
			seed += 3
		"poor":
			seed -= 2
	seed = posmod(seed, portraits.size())
	return portraits[seed]


## The gold/silver/dull palette, duplicated from vault_machine_ui.gd's
## _color_for_quality() (not shared as a singleton — this file already
## reaches main_ref by duck-typed convention rather than fighting for a
## shared owner of a three-line lookup).
func _color_for_quality(quality: String) -> Color:
	match quality:
		"good":
			return Color(0.85, 0.75, 0.4)
		"common":
			return Color(0.6, 0.6, 0.65)
		"poor":
			return Color(0.4, 0.35, 0.4)
		_:
			return Color(0.5, 0.5, 0.5)


## Procedural glyph inside a vault window — deliberately unlabeled (no
## tooltip explaining it). Sized from the record's genome psi, drawn via
## CanvasItem's `draw` signal since Control.new() here carries no script
## of its own to override _draw() with.
func _draw_vault_glyph(glyph: Control, rec: Dictionary) -> void:
	var stat_val := 0.5
	var g = rec.get("genome")
	if g:
		stat_val = clampf(g.psi, 0.0, 1.0)
	var col := _color_for_quality(rec.get("quality", ""))
	var center := glyph.size * 0.5
	# 9.0 -> 3.0 * PHI^2 (canon/01b-sacred-geometry.md).
	var radius := 3.0 + stat_val * (3.0 * SacredGeometryScript.ladder(2.0))
	glyph.draw_circle(center, radius, col)
