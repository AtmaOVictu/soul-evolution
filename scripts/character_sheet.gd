extends Control
## Character sheet — D&D-style panel showing the soul's genome and abilities.
## Press TAB to open/close.

var genome: RefCounted
# World-level state (dust/balance/vault) lives on main.gd, not the genome —
# it's not soul-intrinsic. Read via duck-typed access, same pattern
# hex_grid.gd already uses for world_color/color_balance.
var main_ref: Node = null
var title_label: Label
var polar_label: Label
var ability_vals: Dictionary = {}
var pool_labels: Dictionary = {}
var skull_label: Label
var psi_val_label: Label
var story_label: Label
var power_vals: Dictionary = {}
var mithjos_vals: Dictionary = {}
var upgrade_points_label: Label
var upgrade_list_label: Label
var dust_val_label: Label
var balance_val_label: Label
var vault_val_label: Label
var mods_val_label: Label


func _ready() -> void:
	_build_panel()
	visible = false


func set_genome(g: RefCounted) -> void:
	genome = g
	_refresh()


func _build_panel() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.09, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var sheet := PanelContainer.new()
	sheet.custom_minimum_size = Vector2(520, 620)
	center.add_child(sheet)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	sheet.add_child(vbox)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(title_label)

	polar_label = Label.new()
	polar_label.add_theme_font_size_override("font_size", 14)
	polar_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(polar_label)
	_sep(vbox)

	var names := ["STR", "STA", "INT", "WIS", "CHA", "DEX", "LUK"]
	var desc := {"STR": "strength", "STA": "stamina", "INT": "intelligence", "WIS": "wisdom", "CHA": "charisma", "DEX": "dexterity", "LUK": "luck"}
	for a_name in names:
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var lbl := Label.new()
		lbl.text = "%-3s  %s" % [a_name, desc[a_name]]
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", 15)
		val.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		row.add_child(val)
		ability_vals[a_name] = val
	_sep(vbox)

	# --- 8 Powers (THE BOX) ---
	var pow_title := Label.new()
	pow_title.text = "\u2014 POWERS \u2014"
	pow_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pow_title.add_theme_font_size_override("font_size", 11)
	pow_title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(pow_title)
	var pow_names := ["fizicna", "psiholoska", "custvena", "duhovna", "dusevna", "inteligenca", "gibljivost", "stamina"]
	for pname in pow_names:
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var lbl := Label.new()
		lbl.text = "%-14s" % pname
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", 13)
		val.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		row.add_child(val)
		power_vals[pname] = val
	_sep(vbox)

	# --- 4 Mithjos Dynamics ---
	var mith_title := Label.new()
	mith_title.text = "\u2014 MITHJOS (Z\u00B7J\u00B7E\u00B7N) \u2014"
	mith_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mith_title.add_theme_font_size_override("font_size", 11)
	mith_title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(mith_title)
	var mith_names := [["Z", "zavest"], ["J", "ego"], ["E", "etika"], ["N", "paradoks"]]
	for pair in mith_names:
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var lbl := Label.new()
		lbl.text = "%s  %s" % [pair[0], pair[1]]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", 13)
		val.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		row.add_child(val)
		mithjos_vals[pair[0]] = val
	_sep(vbox)

	# --- Pools ---
	for pool_name in ["capacity", "reflex", "aura"]:
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var lbl := Label.new()
		var icon := "\u2661" if pool_name == "capacity" else ("\u27F3" if pool_name == "reflex" else "\u2727")
		lbl.text = "%s %s" % [icon, pool_name]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", 14)
		row.add_child(val)
		pool_labels[pool_name] = val
	_sep(vbox)

	skull_label = Label.new()
	skull_label.add_theme_font_size_override("font_size", 15)
	skull_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	vbox.add_child(skull_label)
	_sep(vbox)

	# --- World (dust, color balance, vault, modifications) — not soul-intrinsic ---
	var world_title := Label.new()
	world_title.text = "— WORLD —"
	world_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_title.add_theme_font_size_override("font_size", 11)
	world_title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(world_title)
	dust_val_label = _add_row(vbox, "⚙ dust")
	balance_val_label = _add_row(vbox, "⚖ balance")
	vault_val_label = _add_row(vbox, "◉ vault")
	mods_val_label = Label.new()
	mods_val_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	mods_val_label.add_theme_font_size_override("font_size", 12)
	mods_val_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.65))
	vbox.add_child(mods_val_label)
	_sep(vbox)

	# --- Upgrades ---
	upgrade_points_label = Label.new()
	upgrade_points_label.add_theme_font_size_override("font_size", 14)
	upgrade_points_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	vbox.add_child(upgrade_points_label)
	upgrade_list_label = Label.new()
	upgrade_list_label.add_theme_font_size_override("font_size", 12)
	upgrade_list_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	upgrade_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(upgrade_list_label)
	_sep(vbox)

	var gene_title := Label.new()
	gene_title.text = "\u2014 GENOME (the plane\u2019s code) \u2014"
	gene_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gene_title.add_theme_font_size_override("font_size", 11)
	gene_title.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	vbox.add_child(gene_title)

	var gene_eq := Label.new()
	gene_eq.text = "Psi(x) = div_inf(pi(x)) / neg(neg(x)) + del*x * trace"
	gene_eq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gene_eq.add_theme_font_size_override("font_size", 13)
	gene_eq.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	vbox.add_child(gene_eq)

	psi_val_label = Label.new()
	psi_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	psi_val_label.add_theme_font_size_override("font_size", 12)
	psi_val_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(psi_val_label)
	_sep(vbox)

	var story_title := Label.new()
	story_title.text = "\u2014 STORY \u2014"
	story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_title.add_theme_font_size_override("font_size", 11)
	story_title.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	vbox.add_child(story_title)

	story_label = Label.new()
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	story_label.add_theme_font_size_override("font_size", 13)
	story_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.55))
	story_label.custom_minimum_size.y = 60
	vbox.add_child(story_label)


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


func _refresh() -> void:
	if not genome:
		return
	title_label.text = "SOUL #%04d" % genome.soul_id
	polar_label.text = "%s %s" % [
		genome.get_symbol_text(),
		"WHITE / CREATION" if genome.polarity == 0 else "BLACK / DESTRUCTION"
	]
	for key in ability_vals:
		ability_vals[key].text = str(genome.get(key))
	pool_labels["capacity"].text = "%d / %d" % [genome.capacity_current, genome.capacity_max]
	pool_labels["reflex"].text = str(genome.get_reflex())
	pool_labels["aura"].text = str(genome.get_aura())
	var skull_str := "\u2620 SKULLS  "
	for i in genome.skulls:
		skull_str += "\u2593"
	for i in maxi(0, 10 - genome.skulls):
		skull_str += "\u2591"
	skull_label.text = "%s  %d" % [skull_str, genome.skulls]
	if main_ref:
		if "dust" in main_ref:
			dust_val_label.text = str(main_ref.dust)
		if "color_balance" in main_ref:
			var b: float = main_ref.color_balance
			var b_desc := "neutral"
			if b > 0.15:
				b_desc = "white-leaning"
			elif b < -0.15:
				b_desc = "black-leaning"
			balance_val_label.text = "%.2f (%s)" % [b, b_desc]
		if "soul_vault" in main_ref and main_ref.soul_vault:
			vault_val_label.text = main_ref.soul_vault.get_vault_summary()
	if genome.has_method("get_modification_summary"):
		mods_val_label.text = "mods: %s" % genome.get_modification_summary()
	psi_val_label.text = "div %.2f  neg %.2f  del %.2f  trace %.2f  tau %.2f  sig %.2f  C %.2f  N %.2f  P %.2f  S %.2f  Psi=%.3f" % [
		genome.divergence, genome.negation, genome.delta, genome.trace,
		genome.tau, genome.sigma, genome.carbon, genome.nitrogen,
		genome.phosphorus, genome.sulfur, genome.psi
	]
	power_vals["fizicna"].text = "%.2f" % genome.pow_fizicna
	power_vals["psiholoska"].text = "%.2f" % genome.pow_psiholoska
	power_vals["custvena"].text = "%.2f" % genome.pow_custvena
	power_vals["duhovna"].text = "%.2f" % genome.pow_duhovna
	power_vals["dusevna"].text = "%.2f" % genome.pow_dusevna
	power_vals["inteligenca"].text = "%.2f" % genome.pow_inteligenca
	power_vals["gibljivost"].text = "%.2f" % genome.pow_gibljivost
	power_vals["stamina"].text = "%.2f" % genome.pow_stamina_val
	mithjos_vals["Z"].text = "%.2f" % genome.mithjos_Z
	mithjos_vals["J"].text = "%.2f" % genome.mithjos_J
	mithjos_vals["E"].text = "%.2f" % genome.mithjos_E
	mithjos_vals["N"].text = "%.2f" % genome.mithjos_N
	upgrade_points_label.text = "\u2B50 UPGRADE POINTS: %d" % genome.upgrade_points
	var ul := ""
	var cats := ["laser_dmg", "laser_rng", "devour_win", "devour_bst", "speed"]
	var lvls := [genome.laser_damage_level, genome.laser_range_level, genome.devour_window_level, genome.devour_burst_level, genome.speed_level]
	for i in cats.size():
		ul += "  %s Lv.%d" % [genome.get_upgrade_name(cats[i]), lvls[i]]
	upgrade_list_label.text = ul
	var txt := ""
	for line in genome.story_lines:
		txt += "\"%s\"\n" % line
	for frag in genome.fragments_touched:
		txt += "\u2192 %s\n" % frag
	if txt.is_empty():
		txt = "(no story yet \u2014 the soul is new)"
	story_label.text = txt
