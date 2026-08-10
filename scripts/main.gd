extends Control
## Soul Evolution — Phase 0: The Blank Soul
## Main controller: choice screen, void background, soul spawning, HUD.
##
## "We are simulating reality by constructing narratives."
## Everything starts black and white. Adding color is adding substance.
## The abilities are crude — "blasts/farts" — honest about the beginning.

enum GameState { MAIN_MENU, CHOOSING, PLAYING, PAUSED, SETTINGS }

const SacredGeometryScript := preload("res://scripts/sacred_geometry.gd")
const ReactionEngineScript := preload("res://scripts/reaction_engine.gd")
const PurposeLadderScript := preload("res://scripts/purpose_ladder.gd")
const NARR_BASE := 1.0  # narration/HUD timing base (canon/01b-sacred-geometry.md); NOT gameplay balance

var state: GameState = GameState.MAIN_MENU
var soul_polarity: int = 0  # 0 = white/creation, 1 = black/destruction
var play_time: float = 0.0
var first_blast_message_shown: bool = false
var soul_counter: int = 0
var soul_genome: RefCounted = null
var character_sheet: Control = null
var obstacle_rects: Array[ColorRect] = []
var obstacle_hp: Array[int] = []
var obstacle_max_hp: Array[int] = []

# --- UI containers ---
var main_menu_container: CenterContainer
var polarity_container: CenterContainer
var pause_container: CenterContainer
var settings_container: CenterContainer
var gallery_ui: Control = null

# --- Campaign ---
var campaign_phase: int = 0  # 0=monochrome, 1=first color, 2=battle, 3=plane
var color_unlocked: bool = false
var death_count: int = 0
var substance: int = 0
var pandora_opened: bool = false
var pandora_threshold: int = 8
var world_color: int = 0  # color accumulated from annihilation — saturates the world

# --- Grand Council (canon/00-mythos.md act 3; CRITICAL_BRIEF.md §3/§8) ---
# Its own system, not folded into battle-end/campaign_phase: the Council is a
# distinct forced event (movement locks, a choice, a Rebirth), not just
# another battle-end state. council_active gates the modal + pauses combat;
# battle_active is the actual movement/AI gate (see _update_army_ai).
var council_active: bool = false
# Threshold on death_count, which increments by 2 per annihilation
# (_check_annihilation — one white + one black soul die together) and by 1
# per other combat death (_update_army_ai's get_life_pct() <= 0 path). 40
# is effectively "both starting armies (2 * army_size) are gone" — the
# mythos's "last members of black and white."
var council_threshold: int = 40
var council_ui: Control = null
var feats_gained: int = 0

# --- Battle system ---
var soul_stream: RefCounted = null
var soul_vault: RefCounted = null
var white_army: Array = []
var black_army: Array = []
var active_body: Node2D = null
var battle_active: bool = false
var army_size: int = 20

# --- Neutron remnants (the third state) + dust ---
# Its own system, not folded into obstacle_rects/substance: a neutron is a
# conceptually different thing from a destructible wall, and dust is a
# conceptually different resource from substance. See CRITICAL_BRIEF.md §8-9.
var neutron_remnants: Array = []
var dust: int = 0

# --- Color balance (its own system — a rubber-band signal, not world_color) ---
# -1.0 = all black, 0.0 = neutral middle, +1.0 = all white. Currently expressed
# via the background only; the "disadvantaged side deals more damage" half
# has nowhere to attach yet — there is no soul-vs-soul combat damage system at
# all (beam/force-field only ever hit obstacles/neutron_remnants; souls only
# fight each other via contact-annihilation, which is binary, not damage-based).
var color_balance: float = 0.0
var dust_label: Label = null
var vault_ui: Control = null

var void_bg: ColorRect
var hud: CanvasLayer
var polarity_label: Label
var instruction_label: Label
var first_blast_label: Label
var flavor_label: Label
var reaction_label: Label
var purpose_label: Label
var sigil_rect: TextureRect

# Reaction / Purpose systems (canon: parcels sound-physics, mandala-algebra).
var reaction_engine: RefCounted = null
var purpose_ladder: RefCounted = null
var reaction_timer: float = 0.0
var _reaction_act: Array[String] = []
var narrator_label: Label
var narrator_timer: float = 0.0
var void_shader: ShaderMaterial


func _ready() -> void:
	soul_vault = SoulVault.new()
	_build_void()
	_build_hex_grid()
	_build_hud()
	_build_main_menu()
	_build_polarity_choice()
	_build_settings()
	_build_pause_menu()
	# Auto-test mode: skip menu, auto-choose white
	if OS.has_feature("test") or "--auto" in OS.get_cmdline_args():
		print("[TEST] Auto-test mode active")
		call_deferred("_auto_test")


## Integration smoke test — drives the real running game (not isolated like
## scripts/tests/unit_tests.gd) and asserts on the results instead of just
## printing numbers for a human to eyeball. Some values are inherently
## noisy (concurrent AI/annihilation keeps running during every await), so
## assertions are written to hold regardless of that noise — see comments.
var _t_pass := 0
var _t_fail := 0
var _t_failures: Array[String] = []


func _t_assert(cond: bool, desc: String) -> void:
	if cond:
		_t_pass += 1
	else:
		_t_fail += 1
		_t_failures.append(desc)
		print("[TEST]  FAIL: ", desc)


func _auto_test() -> void:
	print("[TEST] Auto-choosing WHITE polarity...")
	_on_polarity_chosen(0)
	await get_tree().create_timer(3.0).timeout

	print("[TEST] --- Spawn state ---")
	_t_assert(white_army.size() == army_size, "white_army spawns at army_size (got %d, want %d)" % [white_army.size(), army_size])
	_t_assert(black_army.size() == army_size, "black_army spawns at army_size (got %d, want %d)" % [black_army.size(), army_size])
	_t_assert(active_body != null and is_instance_valid(active_body), "active_body is set and valid")
	_t_assert(battle_active == true, "battle_active is true after spawn")
	var hex := get_node_or_null("HexGrid")
	_t_assert(hex != null and hex.terrain.size() > 0, "hex terrain is generated")
	if active_body:
		_t_assert(active_body.polarity == 0, "active_body matches the chosen polarity (white)")
		_t_assert(active_body.is_active == true, "active_body has is_active set (movement/ability input gate)")
		_t_assert(active_body.genome != null, "active_body has a genome")

	# Wait and observe — long enough for armies to actually close distance
	# and annihilate at least once (they start ~1500-2000px apart)
	await get_tree().create_timer(15.0).timeout

	print("[TEST] --- After 15s of battle ---")
	_t_assert(active_body != null and is_instance_valid(active_body), "active_body still exists after 15s (incarnation kept it alive)")
	_t_assert(world_color >= 0 and death_count >= 0, "world_color/death_count are non-negative")
	_t_assert(dust >= 0, "dust is never negative")
	# Not asserting world_color > 0 here: whether an annihilation has landed
	# in exactly 15s is itself timing-dependent, tested more directly below.

	print("[TEST] --- Concealment ---")
	# Concurrent AI/annihilation is still running here, same as the asserts
	# above — only check the invariant (alpha stays a valid opacity), not
	# any specific value, since terrain/distance/color_ratio are all live.
	var concealment_ok := true
	for sn in white_army + black_army:
		if is_instance_valid(sn) and (sn.concealment_alpha < 0.0 or sn.concealment_alpha > 1.0):
			concealment_ok = false
	_t_assert(concealment_ok, "every living army member's concealment_alpha stays within [0.0, 1.0]")

	print("[TEST] --- Neutron remnant + dust (direct verification) ---")
	# --auto never simulates a SPACE press, so obstacle/remnant beam collision
	# is otherwise unexercised — teleport onto a remnant and fire directly to
	# prove the collision path itself, not just assert it by analogy.
	if neutron_remnants.size() > 0 and active_body and is_instance_valid(active_body):
		var target: Node2D = neutron_remnants[0]
		var dust_before_fire := dust
		if is_instance_valid(target):
			active_body.position = target.position - Vector2(100.0, 0.0)
			active_body.facing_angle = 0.0
			for i in 6:
				active_body._fire_ability()
				await get_tree().create_timer(0.35).timeout
			_t_assert(dust >= dust_before_fire, "dust never decreases from firing at a remnant")
			if not is_instance_valid(target):
				_t_assert(dust > dust_before_fire, "destroying the targeted remnant increased dust (got +%d)" % [dust - dust_before_fire])
	else:
		print("[TEST]  (skipped: no neutron remnant existed yet at the 15s mark)")

	print("[TEST] --- Force field push on neutron remnant (direct verification) ---")
	# Same reasoning as the block above: --auto never holds SPACE, so the
	# force-field push added to _check_force_field() is otherwise
	# unexercised. Set the force-field state directly on active_body and
	# call _check_force_field() once rather than waiting for real input.
	var ff_target: Node2D = null
	for r in neutron_remnants:
		if is_instance_valid(r):
			ff_target = r
			break
	if ff_target and active_body and is_instance_valid(active_body):
		active_body.position = ff_target.position - Vector2(40.0, 0.0)
		active_body.force_field_active = true
		active_body.force_field_strength = 1.0
		var ff_pos_before: Vector2 = ff_target.position
		_check_force_field()
		active_body.force_field_active = false
		active_body.force_field_strength = 0.0
		_t_assert(ff_target.position != ff_pos_before, "force field push moved the neutron remnant's position")
	else:
		print("[TEST]  (skipped: no valid neutron remnant existed at this point)")

	print("[TEST] --- Soul Vault ---")
	var dust_before_pull := dust
	_open_gumball_machine()
	if dust_before_pull >= 1:
		_t_assert(dust == dust_before_pull - 1, "a successful pull spends exactly 1 dust (had %d, now %d)" % [dust_before_pull, dust])
		_t_assert(soul_vault != null and soul_vault.souls.size() > 0, "a successful pull records a soul in the vault")
	else:
		_t_assert(dust == dust_before_pull, "a refused pull (no dust) does not spend anything")

	print("[TEST] --- Character sheet ---")
	_t_assert(character_sheet != null, "character_sheet exists (was never created in the real battle flow before this fix)")
	if character_sheet:
		character_sheet.visible = true
		character_sheet._refresh()
		_t_assert(not character_sheet.dust_val_label.text.is_empty(), "sheet's dust field populates")
		_t_assert(not character_sheet.balance_val_label.text.is_empty(), "sheet's balance field populates")
		_t_assert(not character_sheet.vault_val_label.text.is_empty(), "sheet's vault field populates")
		_t_assert(character_sheet.dust_val_label.text == str(dust), "sheet's dust field matches the real dust value")

	print("[TEST] --- The Hourglass (direct verification) ---")
	dust = 7
	var color_before_pour := world_color
	_pour_hourglass()
	var gained := world_color - color_before_pour
	_t_assert(dust == 0, "pouring the hourglass spends all held dust")
	# Rate is echo-priced (0.5x-1.5x, see _pour_hourglass), not flat 1:1 —
	# assert the payout lands in that range rather than an exact value.
	_t_assert(gained >= int(round(7 * 0.5)) and gained <= int(round(7 * 1.5)),
		"pouring converts dust to world_color within the 0.5x-1.5x echo-priced range (got +%d for 7 dust)" % gained)
	_pour_hourglass()
	_t_assert(world_color == color_before_pour + gained, "pouring an empty hourglass does not change world_color")

	print("[TEST] --- Grand Council (direct verification) ---")
	# council_threshold (40) won't be reached naturally in this 15s+ window,
	# so force it directly — same pattern as the neutron remnant block above.
	death_count = council_threshold
	_check_grand_council()
	_t_assert(council_active == true, "council_active is true once death_count crosses council_threshold")
	_t_assert(battle_active == false, "battle_active is false while the council is active")
	_resolve_council("split")
	_t_assert(battle_active == true, "battle_active is true again after the council resolves (Rebirth)")
	_t_assert(council_active == false, "council_active is false again after the council resolves")
	_t_assert(death_count == 0, "death_count resets to 0 on Rebirth")
	_t_assert(feats_gained == 1, "feats_gained increments by exactly 1 on Rebirth")
	_t_assert(white_army.size() > 0, "white_army still has survivors after the council")
	_t_assert(black_army.size() > 0, "black_army still has survivors after the council")

	print("[TEST] === RESULTS: %d passed, %d failed ===" % [_t_pass, _t_fail])
	if _t_fail > 0:
		for f in _t_failures:
			print("[TEST]  - ", f)
	print("[TEST] === AUTO TEST COMPLETE ===")
	# Exit automatically so --auto behaves as a real automated smoke test
	# rather than leaving the game window open indefinitely — exit code
	# reflects pass/fail for CI-style usage.
	get_tree().quit(1 if _t_fail > 0 else 0)


func _process(delta: float) -> void:
	if state == GameState.PLAYING:
		play_time += delta
		if play_time > NARR_BASE * SacredGeometryScript.ladder(1.5) and not first_blast_message_shown:  # 2.0 -> 2.058
			_show_first_blast_hint()
		_check_projectile_collisions()
		_check_soul_obstacle_collision()
		_check_force_field()
		_check_neutron_remnant_collisions()
		_check_neutron_remnant_blocking()
		_update_army_ai(delta)
		_update_active_body(delta)
		_update_reaction_system(delta)
		_update_effects(delta)
		if dust_label:
			dust_label.text = (L.t("hud_dust") + " %d") % dust if dust > 0 else ""
		# Narrator speaks periodically (more often now)
		narrator_timer += delta
		if narrator_timer > NARR_BASE * SacredGeometryScript.ladder(3.5):  # 5.0 -> 5.388
			narrator_timer = 0.0
			narrate()
		# Annihilation creates color — the world saturates as souls meet
		var max_color := army_size * 2
		var color_ratio := clampf(float(world_color) / float(max_color), 0.0, 1.0)
		# More annihilation = less desaturation (more color)
		void_shader.set_shader_parameter("desaturation", 1.0 - color_ratio)


func _input(event: InputEvent) -> void:
	if state != GameState.PLAYING:
		return
	# Scroll wheel zoom
	if event is InputEventMouseButton:
		if active_body and is_instance_valid(active_body):
			var cam := active_body.get_node_or_null("Camera")
			if cam:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					cam.zoom = (cam.zoom + Vector2(0.1, 0.1)).min(Vector2(4.0, 4.0))
					get_viewport().set_input_as_handled()
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					cam.zoom = (cam.zoom - Vector2(0.1, 0.1)).max(Vector2(0.12, 0.12))
					get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if state == GameState.PLAYING:
				_show_pause()
			elif state == GameState.PAUSED:
				_on_resume()
		if event.keycode == KEY_TAB:
			_toggle_character_sheet()
		if event.keycode == KEY_G:
			_open_gumball_machine()
		if event.keycode == KEY_H:
			_pour_hourglass()
		if event.keycode == KEY_SPACE and soul_genome and soul_polarity == 0:
			var soul := get_node_or_null("Soul")
			if soul and soul.has_method("_fire_ability"):
				soul._fire_ability()


# --- VOID BACKGROUND ---

func _build_void() -> void:
	void_bg = ColorRect.new()
	void_bg.name = "Void"
	void_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	void_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	void_bg.color = Color(0.05, 0.05, 0.07)
	var shader_src = preload("res://shaders/void.gdshader")
	void_shader = ShaderMaterial.new()
	void_shader.shader = shader_src
	void_shader.set_shader_parameter("polarity", 0.0)
	void_bg.material = void_shader
	add_child(void_bg)


# --- HEX GRID ---

func _build_hex_grid() -> void:
	var HexGridScript = preload("res://scripts/hex_grid.gd")
	var hex_node := Node2D.new()
	hex_node.name = "HexGrid"
	hex_node.set_script(HexGridScript)
	hex_node.z_index = -1
	add_child(hex_node)


# --- MAIN MENU ---

func _build_main_menu() -> void:
	main_menu_container = CenterContainer.new()
	main_menu_container.name = "MainMenu"
	main_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = L.t("menu_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	vbox.add_child(title)
	var sub := Label.new()
	sub.text = L.t("menu_sub")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	vbox.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 30
	vbox.add_child(spacer)
	var play_btn := Button.new()
	play_btn.text = L.t("menu_play")
	play_btn.custom_minimum_size = Vector2(300, 50)
	play_btn.add_theme_font_size_override("font_size", 22)
	play_btn.pressed.connect(_on_play_pressed)
	vbox.add_child(play_btn)
	var settings_btn := Button.new()
	settings_btn.text = L.t("menu_settings")
	settings_btn.custom_minimum_size = Vector2(300, 50)
	settings_btn.pressed.connect(_on_settings_pressed)
	vbox.add_child(settings_btn)
	var gallery_btn := Button.new()
	gallery_btn.text = L.t("menu_gallery")
	gallery_btn.custom_minimum_size = Vector2(300, 50)
	gallery_btn.pressed.connect(_on_gallery_pressed)
	vbox.add_child(gallery_btn)
	var quit_btn := Button.new()
	quit_btn.text = L.t("menu_quit")
	quit_btn.custom_minimum_size = Vector2(300, 50)
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)
	main_menu_container.add_child(vbox)
	add_child(main_menu_container)


func _on_play_pressed() -> void:
	main_menu_container.visible = false
	polarity_container.visible = true
	state = GameState.CHOOSING


func _on_settings_pressed() -> void:
	main_menu_container.visible = false
	settings_container.visible = true
	state = GameState.SETTINGS


func _on_gallery_pressed() -> void:
	if not gallery_ui:
		var ui_script = preload("res://scripts/asset_gallery_ui.gd")
		gallery_ui = Control.new()
		gallery_ui.name = "AssetGallery"
		gallery_ui.set_script(ui_script)
		gallery_ui.back_pressed.connect(_on_gallery_back)
		add_child(gallery_ui)
	main_menu_container.visible = false
	gallery_ui.visible = true


func _on_gallery_back() -> void:
	gallery_ui.visible = false
	main_menu_container.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_to_menu() -> void:
	polarity_container.visible = false
	main_menu_container.visible = true
	state = GameState.MAIN_MENU


func _on_settings_back() -> void:
	settings_container.visible = false
	main_menu_container.visible = true
	state = GameState.MAIN_MENU


# --- POLARITY CHOICE ---

func _build_polarity_choice() -> void:
	polarity_container = CenterContainer.new()
	polarity_container.name = "PolarityChoice"
	polarity_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = L.t("menu_choose_polarity")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(title)
	var sub := Label.new()
	sub.text = L.t("menu_choose_sub")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	vbox.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	var white_btn := Button.new()
	white_btn.text = L.t("menu_white")
	white_btn.custom_minimum_size = Vector2(380, 56)
	white_btn.add_theme_font_size_override("font_size", 18)
	white_btn.pressed.connect(_on_polarity_chosen.bind(0))
	vbox.add_child(white_btn)
	var black_btn := Button.new()
	black_btn.text = L.t("menu_black")
	black_btn.custom_minimum_size = Vector2(380, 56)
	black_btn.add_theme_font_size_override("font_size", 18)
	black_btn.pressed.connect(_on_polarity_chosen.bind(1))
	vbox.add_child(black_btn)
	var back_btn := Button.new()
	back_btn.text = L.t("menu_back")
	back_btn.custom_minimum_size = Vector2(200, 40)
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(_on_back_to_menu)
	vbox.add_child(back_btn)
	polarity_container.add_child(vbox)
	polarity_container.visible = false
	add_child(polarity_container)


# --- PAUSE MENU ---

func _build_pause_menu() -> void:
	pause_container = CenterContainer.new()
	pause_container.name = "PauseMenu"
	pause_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = L.t("menu_paused")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(title)
	var resume_btn := Button.new()
	resume_btn.text = L.t("menu_resume")
	resume_btn.custom_minimum_size = Vector2(280, 50)
	resume_btn.add_theme_font_size_override("font_size", 20)
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)
	var menu_btn := Button.new()
	menu_btn.text = L.t("menu_return")
	menu_btn.custom_minimum_size = Vector2(280, 50)
	menu_btn.add_theme_font_size_override("font_size", 16)
	menu_btn.pressed.connect(_return_to_main_menu)
	vbox.add_child(menu_btn)
	pause_container.add_child(vbox)
	pause_container.visible = false
	pause_container.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.add_child(pause_container)


# --- SETTINGS PANEL ---

func _build_settings() -> void:
	settings_container = CenterContainer.new()
	settings_container.name = "Settings"
	settings_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_container.add_child(bg)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = L.t("menu_settings")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	var army_label := Label.new()
	army_label.text = L.t("menu_army") % army_size
	army_label.add_theme_font_size_override("font_size", 16)
	army_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(army_label)
	var back_btn := Button.new()
	back_btn.text = L.t("menu_back")
	back_btn.custom_minimum_size = Vector2(200, 40)
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(_on_settings_back)
	vbox.add_child(back_btn)
	settings_container.add_child(vbox)
	settings_container.visible = false
	add_child(settings_container)


# --- PAUSE / RETURN TO MENU ---

func _on_resume() -> void:
	pause_container.visible = false
	get_tree().paused = false
	state = GameState.PLAYING


func _show_pause() -> void:
	state = GameState.PAUSED
	pause_container.visible = true
	get_tree().paused = true


func _return_to_main_menu() -> void:
	pause_container.visible = false
	get_tree().paused = false
	_cleanup_battle()
	state = GameState.MAIN_MENU
	main_menu_container.visible = true
	hud.visible = false


func _cleanup_battle() -> void:
	battle_active = false
	for sn in white_army:
		if is_instance_valid(sn):
			sn.queue_free()
	for sn in black_army:
		if is_instance_valid(sn):
			sn.queue_free()
	white_army.clear()
	black_army.clear()
	active_body = null
	for rect in obstacle_rects:
		if is_instance_valid(rect):
			rect.queue_free()
	obstacle_rects.clear()
	obstacle_hp.clear()
	obstacle_max_hp.clear()
	for rem in neutron_remnants:
		if is_instance_valid(rem):
			rem.queue_free()
	neutron_remnants.clear()


# --- HUD ---

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	polarity_label = Label.new()
	polarity_label.add_theme_font_size_override("font_size", 18)
	polarity_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(polarity_label)
	instruction_label = Label.new()
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	vbox.add_child(instruction_label)
	first_blast_label = Label.new()
	first_blast_label.text = ""
	first_blast_label.add_theme_font_size_override("font_size", 14)
	first_blast_label.add_theme_color_override("font_color", Color(0.55, 0.5, 0.4))
	first_blast_label.visible = false
	vbox.add_child(first_blast_label)
	dust_label = Label.new()
	dust_label.text = ""
	dust_label.add_theme_font_size_override("font_size", 13)
	dust_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.42))
	vbox.add_child(dust_label)
	# Reaction / Purpose readout (canon: word-protocol + ascending chain).
	reaction_label = Label.new()
	reaction_label.text = ""
	reaction_label.add_theme_font_size_override("font_size", 13)
	reaction_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	vbox.add_child(reaction_label)
	purpose_label = Label.new()
	purpose_label.text = ""
	purpose_label.add_theme_font_size_override("font_size", 13)
	purpose_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.55))
	vbox.add_child(purpose_label)
	# The Blender-rendered operator sigil of the soul's current act.
	sigil_rect = TextureRect.new()
	sigil_rect.custom_minimum_size = Vector2(40, 40)
	sigil_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Without this, a TextureRect sizes itself to its texture's native
	# resolution (the sigil PNGs are full-size renders, not 40x40 icons) —
	# custom_minimum_size is only a floor, not a ceiling. This was almost
	# certainly what rendered as a giant shape in the middle of the screen.
	sigil_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sigil_rect.visible = false
	vbox.add_child(sigil_rect)
	flavor_label = Label.new()
	flavor_label.text = ""
	flavor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	flavor_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	flavor_label.add_theme_font_size_override("font_size", 13)
	flavor_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	flavor_label.visible = false
	hud.add_child(flavor_label)
	# Narrator — always present, always commenting
	narrator_label = Label.new()
	narrator_label.text = ""
	narrator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	narrator_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	narrator_label.add_theme_font_size_override("font_size", 15)
	narrator_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	narrator_label.visible = false
	hud.add_child(narrator_label)
	hud.visible = false


func _show_first_blast_hint() -> void:
	first_blast_message_shown = true
	first_blast_label.visible = true
	first_blast_label.text = L.t("narr_first_blast")
	first_blast_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(NARR_BASE * SacredGeometryScript.ladder(3.5))  # 5.0 -> 5.388
	tween.tween_property(first_blast_label, "modulate:a", 0.0, NARR_BASE * SacredGeometryScript.ladder(1.5))  # 2.0 -> 2.058
	tween.tween_callback(func(): first_blast_label.visible = false)


func show_flavor(text: String, duration: float = 4.236) -> void:  # 4.0 -> NARR_BASE * PHI^3
	flavor_label.text = text
	flavor_label.modulate.a = 0.0
	flavor_label.visible = true
	var tween := create_tween()
	tween.tween_property(flavor_label, "modulate:a", 1.0, 0.618)  # 0.5 -> PHI^-1
	tween.tween_interval(duration)
	tween.tween_property(flavor_label, "modulate:a", 0.0, 1.0)  # == PHI^0, exact
	tween.tween_callback(func(): flavor_label.visible = false)


# --- NARRATOR ---

var _narrator_lines := [
	# Physics sass
	"you are an electron in a universe that wants to erase you.",
	"the void isn't hostile — it's just matter. and you are the opposite.",
	"every touch is annihilation. try not to touch things.",
	"congratulations, you are a particle. act like one.",
	# Battle commentary
	"the reserves are fighting. bless their hollow little hearts.",
	"your army is doing its best. which is admittedly not much.",
	"someone is shooting something. probably at the right target. probably.",
	"the force field is working. sort of. in theory.",
	"another soul falls. the field barely notices.",
	# Sarcasm about the player
	"you are doing great. the bar was underground, but still.",
	"bold of you to charge into antimatter. stupid, but bold.",
	"the reserves look up to you. which says more about them than you.",
	"you missed. the enemy didn't. think about that.",
	# Philosophical with bite
	"man is a trial, not a certainty. you are proving the trial part.",
	"only in doubt is movement possible. you seem to have plenty of doubt.",
	"the only true value is time. and you are wasting it.",
	"evil doesn't originate from him directly. it originates from your AI.",
	"beseda je dejanje. your actions speak louder. much louder.",
	"resnica ni v dolžini življenja. ampak tvoja duša bo kmalu kratka.",
	# Death/incarnation
	"the field excites. a new particle awakens. it's probably confused.",
	"you died. the universe didn't notice. moving on.",
	"incarnation complete. new body, same existential dread.",
	"the original is gone. the replacement will do. barely.",
	# Random chaos
	"something is happening. I'm not sure what. neither are you.",
	"the hexagonal grid is very pretty. no one is looking at it.",
	"if you squint, this looks like physics. if you don't, it looks like art.",
	"the narrator is tired. but the battle continues.",
]


func narrate(text: String = "") -> void:
	if text.is_empty():
		text = _narrator_lines[randi() % _narrator_lines.size()]
	narrator_label.text = text
	narrator_label.modulate.a = 0.0
	narrator_label.visible = true
	var tween := create_tween()
	tween.tween_property(narrator_label, "modulate:a", 0.786, 0.786)  # 0.8 -> PHI^-0.5
	tween.tween_interval(3.330)  # 3.0 -> PHI^2.5
	tween.tween_property(narrator_label, "modulate:a", 0.0, 1.618)  # 1.5 -> PHI^1
	tween.tween_callback(func(): narrator_label.visible = false)


# --- POLARITY CHOICE -> GAME START ---

func _on_polarity_chosen(chosen: int) -> void:
	soul_polarity = chosen
	_start_game()


func _start_game() -> void:
	state = GameState.PLAYING
	polarity_container.visible = false
	# Release focus from buttons so SPACE reaches the game
	for child in polarity_container.get_children():
		if child is Control:
			child.release_focus()
	hud.visible = true
	play_time = 0.0
	if soul_polarity == 0:
		polarity_label.text = L.t("hud_soul_white")
		instruction_label.text = L.t("hud_controls_white")
	else:
		polarity_label.text = L.t("hud_soul_black")
		instruction_label.text = L.t("hud_controls_black")
	# Transition void
	var target := float(soul_polarity)
	var tween := create_tween()
	tween.tween_method(_lerp_void_polarity, 0.0, target, 1.272)  # 1.2 -> PHI^0.5
	await tween.finished
	if soul_polarity == 0:
		show_flavor(L.t("narr_light_void"))
	else:
		show_flavor(L.t("narr_void_child"))
	_spawn_obstacles()
	_spawn_army()
	narrate(L.t("narr_first_encounter"))


func _lerp_void_polarity(value: float) -> void:
	void_shader.set_shader_parameter("polarity", value)


# --- SOUL SPAWNING ---

func _spawn_soul() -> void:
	soul_counter += 1
	soul_genome = SoulGenome.create_random(soul_counter, soul_polarity)
	soul_genome.add_story("light enters the void. the first narrative begins." if soul_polarity == 0 else "the void accepts its child. everything begins from nothing.")
	soul_genome.add_fragment("Beseda je nujen izum \u2014 the word is a necessary invention")
	var soul_script = preload("res://scripts/soul.gd")
	var soul_node := Node2D.new()
	soul_node.name = "Soul"
	soul_node.set_script(soul_script)
	soul_node.position = Vector2(640.0, 360.0)
	add_child(soul_node)
	soul_node.polarity = soul_polarity
	soul_node.genome = soul_genome
	soul_node._apply_polarity()
	_ensure_character_sheet()
	character_sheet.set_genome(soul_genome)


func _toggle_character_sheet() -> void:
	if character_sheet:
		character_sheet.visible = not character_sheet.visible
		if character_sheet.visible:
			character_sheet._refresh()


# --- OBSTACLES ---

func _add_wall(x: float, y: float, w: float, h: float, col: Color) -> void:
	var wall := ColorRect.new()
	wall.color = col
	wall.position = Vector2(x, y)
	wall.size = Vector2(w, h)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)
	obstacle_rects.append(wall)
	obstacle_hp.append(9999)
	obstacle_max_hp.append(9999)


func _spawn_obstacles() -> void:
	var count := randi_range(12, 20)
	# Arena walls (border)
	var wall_thick := 8.0
	var arena_w := 2400.0
	var arena_h := 1800.0
	var wall_col := Color(0.18, 0.18, 0.22)
	# Top wall
	_add_wall(0.0, 0.0, arena_w, wall_thick, wall_col)
	# Bottom wall
	_add_wall(0.0, arena_h - wall_thick, arena_w, wall_thick, wall_col)
	# Left wall
	_add_wall(0.0, 0.0, wall_thick, arena_h, wall_col)
	# Right wall
	_add_wall(arena_w - wall_thick, 0.0, wall_thick, arena_h, wall_col)
	# Obstacles
	for i in count:
		var rect := ColorRect.new()
		var hp := randi_range(2, 5)
		var brightness := 0.15 + float(hp) / 5.0 * 0.25
		rect.color = Color(brightness, brightness, brightness + 0.02)
		var w := randf_range(30.0, 70.0)
		var h := randf_range(30.0, 70.0)
		rect.custom_minimum_size = Vector2(w, h)
		rect.position = Vector2(randf_range(100.0, 2300.0), randf_range(100.0, 1700.0))
		rect.size = Vector2(w, h)
		add_child(rect)
		obstacle_rects.append(rect)
		obstacle_hp.append(hp)
		obstacle_max_hp.append(hp)


func _check_projectile_collisions() -> void:
	var soul := active_body
	if not soul or not is_instance_valid(soul) or not soul.has_method("get_active_projectiles"):
		return
	var projectiles: Array[Dictionary] = soul.get_active_projectiles()
	for pi in range(projectiles.size() - 1, -1, -1):
		var proj: Dictionary = projectiles[pi]
		if proj.get("type") != "beam":
			continue
		# Beam collision: convert local coords to global for obstacle check
		var beam_start: Vector2 = soul.position + proj["start"]
		var beam_end: Vector2 = soul.position + proj["end"]
		var beam_hit := false
		for oi in range(obstacle_rects.size() - 1, -1, -1):
			var rect: ColorRect = obstacle_rects[oi]
			var rect_center := rect.position + rect.size * 0.5
			# Simple proximity check: is obstacle center near the beam line?
			var closest := Geometry2D.get_closest_point_to_segment(rect_center, beam_start, beam_end)
			if closest.distance_to(rect_center) < minf(rect.size.x, rect.size.y) * 0.6:
				obstacle_hp[oi] -= int(proj["damage"])
				var ratio := float(obstacle_hp[oi]) / float(obstacle_max_hp[oi])
				var new_b: float = 0.1 + ratio * 0.3
				rect.color = Color(new_b, new_b, new_b + 0.01)
				_spawn_beam_impact(rect_center)
				beam_hit = true
				if obstacle_hp[oi] <= 0:
					rect.queue_free()
					obstacle_rects.remove_at(oi)
					obstacle_hp.remove_at(oi)
					obstacle_max_hp.remove_at(oi)
					if soul_genome:
						soul_genome.upgrade_points += 1
						soul_genome.add_story("the light revealed what was hidden \u2014 substance earned.")
					substance += 1
					_check_pandora()
				break
		if beam_hit and pi < projectiles.size():
			projectiles.remove_at(pi)


func _check_neutron_remnant_collisions() -> void:
	# Beam vs. wreckage — its own check, not merged into the obstacle-beam
	# logic above, because breaking a neutron yields dust, a resource
	# conceptually distinct from substance/upgrade_points.
	var soul := active_body
	if not soul or not is_instance_valid(soul) or not soul.has_method("get_active_projectiles"):
		return
	var projectiles: Array[Dictionary] = soul.get_active_projectiles()
	for pi in range(projectiles.size() - 1, -1, -1):
		var proj: Dictionary = projectiles[pi]
		if proj.get("type") != "beam":
			continue
		var beam_start: Vector2 = soul.position + proj["start"]
		var beam_end: Vector2 = soul.position + proj["end"]
		var beam_hit := false
		for ri in range(neutron_remnants.size() - 1, -1, -1):
			var rem: Node2D = neutron_remnants[ri]
			if not is_instance_valid(rem):
				neutron_remnants.remove_at(ri)
				continue
			var closest := Geometry2D.get_closest_point_to_segment(rem.position, beam_start, beam_end)
			if closest.distance_to(rem.position) < rem.radius * 0.7:
				var destroyed: bool = rem.take_beam_damage(int(proj["damage"]))
				_spawn_beam_impact(rem.position)
				beam_hit = true
				if destroyed:
					dust += randi_range(2, 4)
					rem.queue_free()
					neutron_remnants.remove_at(ri)
				break
		if beam_hit and pi < projectiles.size():
			projectiles.remove_at(pi)


func _check_neutron_remnant_blocking() -> void:
	# Wreckage is solid — the arena narrows as its own war fills it with
	# debris ("movement grows heavy", CRITICAL_BRIEF.md §3/§8).
	if not active_body or not is_instance_valid(active_body):
		return
	for rem in neutron_remnants:
		if not is_instance_valid(rem):
			continue
		var min_dist: float = active_body.radius + rem.radius
		var dist: float = active_body.position.distance_to(rem.position)
		if dist < min_dist and dist > 0.01:
			var push_dir: Vector2 = (active_body.position - rem.position).normalized()
			active_body.position += push_dir * (min_dist - dist)


func _check_force_field() -> void:
	var soul := active_body
	if not soul or not is_instance_valid(soul) or not soul.has_method("get_force_field_range"):
		return
	if not soul.force_field_active or soul.force_field_strength < 0.1:
		return
	var ff_range: float = soul.get_force_field_range()
	var dt := get_process_delta_time()
	for oi in range(obstacle_rects.size()):
		var rect: ColorRect = obstacle_rects[oi]
		var rect_center: Vector2 = rect.position + rect.size * 0.5
		var dist: float = soul.position.distance_to(rect_center)
		if dist < ff_range and dist > 1.0:
			# Mass: heavier obstacles (more HP) resist more
			var mass: float = 2.0 + float(obstacle_max_hp[oi]) * 1.5
			var push_dir: Vector2 = (rect_center - soul.position).normalized()
			var push_force: float = soul.force_field_strength * 60.0 / (mass * maxf(dist * 0.01, 0.5))
			rect.position += push_dir * push_force * dt
			# Clamp to viewport
			var vp: Vector2 = get_viewport_rect().size
			rect.position.x = clampf(rect.position.x, 0.0, vp.x - rect.size.x)
			rect.position.y = clampf(rect.position.y, 0.0, vp.y - rect.size.y)
	# Wreckage verb 3/3: push. Reclaim (_crack_open_nearby_remnants) and
	# degrade (_check_neutron_remnant_collisions) already exist elsewhere;
	# this closes the loop so force fields shove neutron remnants around
	# like any other mass, not just obstacles. Not clamped to the viewport:
	# remnants are world-space wreckage positioned within the hex arena
	# (HexGrid.ARENA_SIZE), not viewport-relative UI rects like obstacle_rects,
	# and the push magnitudes here mirror the obstacle loop above, which
	# in practice keeps remnants well inside the arena.
	for rem in neutron_remnants:
		if not is_instance_valid(rem):
			continue
		var dist2: float = soul.position.distance_to(rem.position)
		if dist2 < ff_range and dist2 > 1.0:
			var mass2: float = 2.0 + float(rem.max_hp) * 1.5
			var push_dir2: Vector2 = (rem.position - soul.position).normalized()
			var push_force2: float = soul.force_field_strength * 60.0 / (mass2 * maxf(dist2 * 0.01, 0.5))
			rem.position += push_dir2 * push_force2 * dt


func _check_soul_obstacle_collision() -> void:
	var soul := active_body
	if not soul or not is_instance_valid(soul) or not soul.has_method("take_damage"):
		return
	for oi in range(obstacle_rects.size() - 1, -1, -1):
		var rect: ColorRect = obstacle_rects[oi]
		var dist: float = soul.position.distance_to(rect.position + rect.size * 0.5)
		if dist < soul.radius + minf(rect.size.x, rect.size.y) * 0.4:
			soul.take_damage(1.0, "enemy")


# ===================================================================
# BATTLE SYSTEM — 100 vs 100, soul-stream incarnates on death
# ===================================================================

## A starting-zone BOX with uniform proportions for one army. The box keeps a
## fixed aspect ratio (uniform width:height) so both sides get an identical,
## deliberately-proportioned spawn area — the "physical boundary" of the start.
## polarity 0 = white (left), 1 = black (right).
func _get_starting_zone(polarity: int, arena: Vector2) -> Rect2:
	# Uniform proportion: the box is always width = 0.30 * arena, height =
	# 0.70 * arena, so its aspect is fixed (0.30/0.70 ~ 0.43) regardless of
	# arena size — uniform on both sides.
	var w := arena.x * 0.30
	var h := arena.y * 0.70
	var cx := arena.x * (0.15 if polarity == 0 else 0.85)
	return Rect2(Vector2(cx - w * 0.5, (arena.y - h) * 0.5), Vector2(w, h))


## A uniformly-random point inside a Rect2 box.
func _random_in_zone(zone: Rect2) -> Vector2:
	return zone.position + Vector2(randf_range(0.0, zone.size.x), randf_range(0.0, zone.size.y))


func _spawn_army() -> void:
	soul_stream = SoulStream.new()
	soul_stream.stream_id = 1
	var arena := Vector2(3440.0, 1440.0)
	var soul_script = preload("res://scripts/soul.gd")
	# Spawn white army (left side) — first soul is the ORIGINAL
	var white_zone := _get_starting_zone(0, arena)
	for i in army_size:
		var sn := Node2D.new()
		sn.name = "White_%d" % i
		sn.set_script(soul_script)
		sn.position = _random_in_zone(white_zone)
		add_child(sn)
		var g := SoulGenome.create_random(soul_counter, 0)
		soul_counter += 1
		# ORIGINAL: born with ego (1.0). RESERVES: hollow (0.0).
		if i == 0:
			g.ego = 1.0
		else:
			g.ego = 0.0
		g._boost_genome(1.25 if i == 0 else 0.75)
		sn.polarity = 0
		sn.genome = g
		sn._apply_polarity()
		white_army.append(sn)
	# Spawn black army (right side) — first soul is the ORIGINAL
	var black_zone := _get_starting_zone(1, arena)
	for i in army_size:
		var sn := Node2D.new()
		sn.name = "Black_%d" % i
		sn.set_script(soul_script)
		sn.position = _random_in_zone(black_zone)
		add_child(sn)
		var g := SoulGenome.create_random(soul_counter, 1)
		soul_counter += 1
		if i == 0:
			g.ego = 1.0
		else:
			g.ego = 0.0
		g._boost_genome(1.25 if i == 0 else 0.75)
		sn.polarity = 1
		sn.genome = g
		sn._apply_polarity()
		black_army.append(sn)
	# Player incarnates into first white soul (the ORIGINAL)
	active_body = white_army[0]
	active_body.is_active = true
	soul_stream.incarnate(active_body.genome)
	# Reaction / Purpose systems — the soul's formation→reaction→purpose loop.
	reaction_engine = ReactionEngineScript.new()
	purpose_ladder = PurposeLadderScript.new()
	reaction_timer = 0.0
	battle_active = true
	_ensure_character_sheet()
	character_sheet.set_genome(active_body.genome)
	_refresh_camera()
	narrate(L.t("narr_first_encounter"))


## character_sheet was previously only ever created in _spawn_soul(), the
## Phase-0 path that nothing in the battle flow calls — meaning TAB has never
## actually opened anything in real gameplay (_toggle_character_sheet and the
## incarnation update both silently no-op on a null character_sheet). This is
## the real creation point.
func _ensure_character_sheet() -> void:
	if character_sheet:
		return
	var sheet_script = preload("res://scripts/character_sheet.gd")
	character_sheet = Control.new()
	character_sheet.name = "CharacterSheet"
	character_sheet.set_script(sheet_script)
	character_sheet.main_ref = self
	character_sheet.visible = false
	hud.add_child(character_sheet)


func _refresh_camera() -> void:
	if active_body:
		var cam := active_body.get_node_or_null("Camera")
		if cam:
			cam.make_current()


func _update_army_ai(delta: float) -> void:
	if not battle_active:
		return
	# Enemies must be relative to each army's OWN side, not the player's side —
	# a single global "enemies" reused for both armies meant black souls were
	# handed black_army as their own enemy list (searching for "nearest enemy"
	# within their own side), and their targeting was effectively meaningless.
	for army in [white_army, black_army]:
		var enemies: Array = black_army if army == white_army else white_army
		for i in range(army.size() - 1, -1, -1):
			var sn: Node2D = army[i]
			if not is_instance_valid(sn):
				army.remove_at(i)
				continue
			if sn.has_method("get_life_pct") and sn.get_life_pct() <= 0:
				# Soul died — remove and count
				death_count += 1
				_spawn_death_effect(sn.position, sn.polarity)
				if sn == active_body:
					_check_incarnation()
				sn.queue_free()
				army.remove_at(i)
				continue
			# AI: move toward nearest enemy, fire periodically
			if sn != active_body:
				_ai_think(sn, enemies, delta)
	_update_concealment(delta)
	_update_color_balance()
	_check_annihilation()
	_check_battle_end()
	_check_grand_council()


func _update_reaction_system(delta: float) -> void:
	# The soul's FORM → REACT → FUEL loop, surfaced on the HUD. Every ~2.5s the
	# soul forms an act (a ∅sentence of operators), the engine reacts, and the
	# reaction fuels the purpose ladder. This is the canon's word-protocol +
	# ascending chain made visible.
	if not battle_active or not active_body or not active_body.genome:
		if reaction_label:
			reaction_label.text = ""
			purpose_label.text = ""
		return
	if _reaction_act.is_empty():
		_reaction_act = engine_form_act()
	if not reaction_engine or not purpose_ladder:
		return
	reaction_timer += delta
	if reaction_timer < 2.5:
		return
	reaction_timer = 0.0
	var g = active_body.genome
	var act: Array[String] = _reaction_act
	var prof: Dictionary = reaction_engine.form_act(g, act)
	var r: Dictionary = reaction_engine.react(g, prof)
	reaction_engine.apply_reaction(g, r)
	var ascended: bool = purpose_ladder.fuel(g, r, r["echo"])
	var ladder: Dictionary = purpose_ladder.to_dict()
	if reaction_label:
		reaction_label.text = "REACT ⟡ %s  echo=%.2f  %s" % ["⊕".join(act), r["echo"], r["verdict"]]
	if purpose_label:
		purpose_label.text = "PURPOSE ▸ %s → %s  purpose=%.2f/%.2f%s" % [
			ladder["current"], ladder["next"], ladder["purpose"], ladder["threshold"],
			("  ▲ ASCENDED" if ascended else "")
		]
	if sigil_rect and act.size() > 0:
		# Show the Blender-rendered sigil for the act's lead operator.
		var sigil_path := "res://assets/sigil_%s.png" % _op_name(act[0])
		if ResourceLoader.exists(sigil_path):
			sigil_rect.texture = load(sigil_path)
			sigil_rect.visible = true


## A default act the soul forms — a ∅sentence of operators drawn from the
## genome's own strongest genes (the soul speaks what it is).
func _op_name(op: String) -> String:
	match op:
		"∇": return "div"
		"¬": return "neg"
		"∆": return "delta"
		"✡": return "trace"
		"τ": return "tau"
		"σ": return "sigma"
	return op


func engine_form_act() -> Array[String]:
	var g = active_body.genome
	var ops := ["∇", "¬", "∆", "✡", "τ", "σ"]
	var genes := {
		"∇": g.divergence, "¬": g.negation, "∆": g.delta,
		"✡": g.trace, "τ": g.tau, "σ": g.sigma,
	}
	# Pick the three strongest operators — the soul's resonance.
	var sorted_keys := ops.duplicate()
	sorted_keys.sort_custom(func(a, b): return genes[a] > genes[b])
	var result: Array[String] = []
	for i in mini(3, sorted_keys.size()):
		result.append(String(sorted_keys[i]))
	return result


func _update_color_balance() -> void:
	# -1.0 = all black, 0.0 = neutral middle, +1.0 = all white.
	var total := white_army.size() + black_army.size()
	color_balance = float(white_army.size() - black_army.size()) / float(maxi(total, 1))


func _update_concealment(delta: float) -> void:
	# Blindness is global and symmetric — "Light notices only what is Light's,
	# Dark notices only what is Dark's" (canon/00-mythos.md) — and lifts as
	# world_color rises ("Color appears when Time facilitates perception").
	# White viewers fade the black army, black viewers fade the white army,
	# using the same color_ratio hex_grid.gd derives for its own void tint.
	if not active_body or not is_instance_valid(active_body):
		return
	var hex := get_node_or_null("HexGrid")
	if not hex:
		return
	var color_ratio: float = clampf(float(world_color) / maxf(float(army_size) * 2.0, 1.0), 0.0, 1.0)
	var reveal_radius: float = lerp(90.0, 420.0, color_ratio)
	var ambush_floor: float = lerp(0.12, 1.0, color_ratio)
	var open_floor: float = lerp(0.55, 1.0, color_ratio)
	var fade_speed: float = clampf(delta * 3.0, 0.0, 1.0)
	var viewer_is_white: bool = active_body.polarity == 0
	var hidden_army: Array = black_army if viewer_is_white else white_army
	var ambush_terrain: int = hex.T_DARK if viewer_is_white else hex.T_LIGHT
	for sn in hidden_army:
		if not is_instance_valid(sn) or sn == active_body:
			continue
		var dist: float = active_body.position.distance_to(sn.position)
		var in_ambush_terrain: bool = hex.get_terrain_at(sn.position) == ambush_terrain
		var target_alpha: float = ambush_floor if in_ambush_terrain else open_floor
		if dist <= reveal_radius:
			target_alpha = 1.0
		sn.concealment_alpha = lerp(sn.concealment_alpha, target_alpha, fade_speed)


func _ai_think(sn: Node2D, enemies: Array, delta: float) -> void:
	if not sn.genome:
		return
	# Determine role: companion (first 3 reserves) or tactical (rest)
	var sn_index: int = -1
	var army: Array = white_army if sn.polarity == 0 else black_army
	for i in range(army.size()):
		if army[i] == sn:
			sn_index = i
			break
	# A soul is only a "companion" (follows the player as leader) if it's on
	# the player's own side — there is no player-analog on the enemy side for
	# them to rally around, so opposite-polarity index-1..3 souls fall through
	# to tactical behavior instead of sitting idle.
	var same_side_as_player: bool = active_body and is_instance_valid(active_body) and sn.polarity == active_body.polarity
	var is_companion: bool = sn_index >= 1 and sn_index <= 3 and same_side_as_player
	var is_tactical: bool = sn_index > 3 or (sn_index >= 1 and sn_index <= 3 and not same_side_as_player)

	# --- COMPANIONS: follow player closely, fight when enemies near ---
	if is_companion and sn != active_body:
		var to_player: Vector2 = active_body.position - sn.position
		var dist: float = to_player.length()
		# Find nearest enemy
		var nearest_e: Node2D = null
		var ne_dist: float = 999999.0
		for e in enemies:
			if is_instance_valid(e):
				var d: float = sn.position.distance_to(e.position)
				if d < ne_dist:
					ne_dist = d
					nearest_e = e
		if sn.polarity == 0:
			# WHITE = coward: fires once, then hides — drifting toward the
			# nearest ally rather than sustaining an advance. Not brave.
			if nearest_e and ne_dist < 350.0:
				sn.facing_angle = (nearest_e.position - sn.position).angle()
				if sn.blast_timer <= 0.0:
					sn._fire_ability()
					sn.blast_timer = 2.5  # long cooldown — the hiding window
				elif ne_dist < 220.0:
					var flee_dir: Vector2 = (sn.position - nearest_e.position).normalized()
					var nearest_ally: Node2D = null
					var na_dist: float = 999999.0
					for a in white_army:
						if is_instance_valid(a) and a != sn:
							var ad: float = sn.position.distance_to(a.position)
							if ad < na_dist:
								na_dist = ad
								nearest_ally = a
					if nearest_ally and na_dist > 40.0:
						flee_dir = (flee_dir + (nearest_ally.position - sn.position).normalized()).normalized()
					sn.position += flee_dir * sn.genome.get_speed() * 0.3 * delta
			else:
				# Follow player tight
				if dist > 50.0:
					sn.position += to_player.normalized() * sn.genome.get_speed() * 0.3 * delta
					sn.facing_angle = to_player.angle()
				elif dist > 25.0:
					var perp := Vector2(-to_player.y, to_player.x).normalized()
					sn.position += perp * sn.genome.get_speed() * 0.08 * delta
		else:
			# BLACK = ambusher: propagates toward dark zones when unengaged —
			# confronted, it does not flee, it surges (rampant).
			if nearest_e and ne_dist < 100.0:
				sn.force_field_active = true
				sn.force_field_strength = minf(1.0, sn.force_field_strength + delta * 6.0)
				sn.position += (nearest_e.position - sn.position).normalized() * sn.genome.get_speed() * 0.15 * delta
				sn.facing_angle = (nearest_e.position - sn.position).angle()
			elif nearest_e and ne_dist < 350.0:
				sn.facing_angle = (nearest_e.position - sn.position).angle()
				sn.force_field_active = true
				sn.force_field_strength = minf(0.6, sn.force_field_strength + delta * 2.0)
			else:
				var hex := get_node_or_null("HexGrid")
				var dark_pos: Vector2 = hex.get_nearest_dark_zone(sn.position) if hex else Vector2.INF
				if dark_pos != Vector2.INF:
					var to_dark: Vector2 = dark_pos - sn.position
					if to_dark.length() > 30.0:
						sn.position += to_dark.normalized() * sn.genome.get_speed() * 0.2 * delta
						sn.facing_angle = to_dark.angle()
				elif dist > 50.0:
					sn.position += to_player.normalized() * sn.genome.get_speed() * 0.3 * delta
	# --- TACTICAL RESERVES: hold formation, but formation is dragged toward the enemy mass ---
	elif is_tactical:
		# Formation shape (spread grid for white, cluster for black) blended with a pull
		# toward the enemy army's centroid — without this pull the two formations sit in
		# disjoint zones (white covers the whole arena, black hugs the center) and never meet.
		var enemy_centroid := Vector2.ZERO
		var enemy_count := 0
		for e in enemies:
			if is_instance_valid(e):
				enemy_centroid += e.position
				enemy_count += 1
		var formation_target: Vector2
		if sn.polarity == 0:
			formation_target = _get_white_tactical_pos(sn)
		else:
			formation_target = _get_black_tactical_pos(sn)
		var final_target := formation_target
		if enemy_count > 0:
			enemy_centroid /= float(enemy_count)
			final_target = formation_target.lerp(enemy_centroid, 0.4)
		var to_target: Vector2 = final_target - sn.position
		if to_target.length() > 20.0:
			# 0.15 (was the value before the WASD-input bug fix) turned out to be
			# too slow to ever close the ~1800px starting gap between armies in
			# reasonable time — that was previously masked by every soul also
			# drifting with the player's raw input. Real AI-only speed needs to
			# be faster now that masking is gone.
			sn.position += to_target.normalized() * sn.genome.get_speed() * 0.35 * delta
		if sn.polarity == 1 and sn.force_field_strength < 0.3:
			# Black: keep force field warm to control territory
			sn.force_field_active = true
			sn.force_field_strength = minf(0.5, sn.force_field_strength + delta * 1.5)
		# Fight if an enemy is within range — radius widened so reserves actually engage
		# instead of drifting past each other on the way to their formation slot.
		var nearest_e: Node2D = null
		var ne_dist: float = 999999.0
		for e in enemies:
			if is_instance_valid(e):
				var d: float = sn.position.distance_to(e.position)
				if d < ne_dist:
					ne_dist = d
					nearest_e = e
		if nearest_e and ne_dist < 450.0:
			sn.facing_angle = (nearest_e.position - sn.position).angle()
			if sn.blast_timer <= 0.0 and sn.polarity == 0 and ne_dist < 350.0:
				sn._fire_ability()
				sn.blast_timer = 1.5
			elif sn.polarity == 1 and ne_dist < 150.0:
				sn.force_field_active = true
				sn.force_field_strength = minf(1.0, sn.force_field_strength + delta * 4.0)
	# Clamp
	sn.position.x = clampf(sn.position.x, 30.0, 2370.0)
	sn.position.y = clampf(sn.position.y, 30.0, 1770.0)


func _get_white_tactical_pos(sn: Node2D) -> Vector2:
	# White souls spread to illuminate maximum area
	# Position in a grid pattern across the arena
	var spacing := 200.0
	var arena_w := 3440.0
	var arena_h := 1440.0
	# Find grid cell for this soul
	var idx := 0
	for i in range(white_army.size()):
		if white_army[i] == sn:
			idx = i
			break
	# Distribute in a grid
	var cols := int(ceil(arena_w / spacing))
	var row := idx / cols
	var col := idx % cols
	return Vector2(float(col) * spacing + 100.0, float(row) * spacing + 100.0)


func _get_black_tactical_pos(sn: Node2D) -> Vector2:
	# Black souls cluster toward center and chokepoints
	var center := Vector2(1720.0, 720.0)
	var idx := 0
	for i in range(black_army.size()):
		if black_army[i] == sn:
			idx = i
			break
	# Cluster in a formation around center
	var angle: float = TAU * float(idx - 4) / float(maxi(black_army.size() - 4, 1))
	var dist: float = 150.0 + float(idx % 3) * 80.0
	return center + Vector2(cos(angle), sin(angle)) * dist


func _check_incarnation() -> void:
	if not soul_stream:
		return
	# The dying body — captured before we search, and explicitly excluded
	# below. Annihilation kills via queue_free() without ever touching HP, so
	# at this point the dying soul can still read get_life_pct() > 0.0 and
	# still be sitting in the army array: without this exclusion the search
	# picks the very soul that's about to be freed two lines later, and no
	# real incarnation happens.
	var dying := active_body
	if active_body and is_instance_valid(active_body):
		active_body.is_active = false
	var army: Array = white_army if soul_stream.current_body and soul_stream.current_body.polarity == 0 else black_army
	for sn in army:
		if sn != dying and is_instance_valid(sn) and sn.has_method("get_life_pct") and sn.get_life_pct() > 0.0:
			# The reserve gains ego (but less than the original)
			sn.genome.ego = 0.8
			sn.genome.set_ego(0.8)
			soul_stream.incarnate(sn.genome)
			active_body = sn
			active_body.is_active = true
			_refresh_camera()
			if character_sheet:
				character_sheet.set_genome(sn.genome)
			narrate(L.t("narr_incarnate"))
			return
	# No souls left — this side lost
	battle_active = false
	narrate(L.t("narr_died"))


func _check_annihilation() -> void:
	# Matter (white) + antimatter (black) contact = annihilation.
	# Both destroyed, energy released as COLOR into the world.
	var white_indices: Array = []
	var black_indices: Array = []
	# Find valid souls
	for i in range(white_army.size()):
		if is_instance_valid(white_army[i]):
			white_indices.append(i)
	for i in range(black_army.size()):
		if is_instance_valid(black_army[i]):
			black_indices.append(i)
	# Check pairs for contact
	for wi in white_indices:
		var white_soul: Node2D = white_army[wi]
		if not is_instance_valid(white_soul):
			continue
		for bi in black_indices:
			var black_soul: Node2D = black_army[bi]
			if not is_instance_valid(black_soul):
				continue
			var dist: float = white_soul.position.distance_to(black_soul.position)
			if dist < white_soul.radius + black_soul.radius + 4.0:
				# ANNIHILATION! Both destroyed, color released — AND a third
				# state: the pair neutralizes into a broken physical remnant,
				# not just an abstract counter. See CRITICAL_BRIEF.md §8.
				var contact_point: Vector2 = (white_soul.position + black_soul.position) * 0.5
				_spawn_annihilation_effect(contact_point)
				_crack_open_nearby_remnants(contact_point)
				_spawn_neutron_remnant(contact_point)
				# Release substance (color) into the world
				substance += 2
				world_color += 1
				color_unlocked = true
				campaign_phase = maxi(campaign_phase, 1)
				death_count += 2
				# Handle active body death
				if white_soul == active_body:
					_check_incarnation()
				if black_soul == active_body:
					_check_incarnation()
				# Remove both (queue_free + remove from arrays)
				white_soul.queue_free()
				black_soul.queue_free()
				white_army[wi] = null
				black_army[bi] = null
				# Narrator
				narrate(L.t("narr_annihilation"))
				break
	# Clean nulls
	for i in range(white_army.size() - 1, -1, -1):
		if white_army[i] == null or not is_instance_valid(white_army[i]):
			white_army.remove_at(i)
	for i in range(black_army.size() - 1, -1, -1):
		if black_army[i] == null or not is_instance_valid(black_army[i]):
			black_army.remove_at(i)


func _spawn_neutron_remnant(pos: Vector2) -> void:
	var remnant_script = preload("res://scripts/neutron_remnant.gd")
	var remnant := Node2D.new()
	remnant.name = "Neutron_%d" % neutron_remnants.size()
	remnant.set_script(remnant_script)
	remnant.position = pos
	add_child(remnant)
	neutron_remnants.append(remnant)


func _crack_open_nearby_remnants(pos: Vector2) -> void:
	# New violence near old wreckage reclaims it — reverts to color instead
	# of staying permanently spent. See CRITICAL_BRIEF.md §8.
	for i in range(neutron_remnants.size() - 1, -1, -1):
		var rem: Node2D = neutron_remnants[i]
		if not is_instance_valid(rem):
			neutron_remnants.remove_at(i)
			continue
		if rem.position.distance_to(pos) < 90.0:
			world_color += 1
			_spawn_annihilation_effect(rem.position)
			rem.queue_free()
			neutron_remnants.remove_at(i)


func _spawn_annihilation_effect(pos: Vector2) -> void:
	# Bright flash + expanding color rings — the energy of creation.
	# Radii/speed/life re-derived from PHI, hex_size as the spatial base
	# (canon/01b-sacred-geometry.md); alpha (0.8) is below the ladder's
	# useful resolution and left as an art-direction literal.
	for i in 6:
		_effects.append({
			"pos": pos,
			"radius": 4.86 + float(i) * 6.18,                                   # 5.0/6.0
			"max_radius": 64.72 + float(i) * 19.43,                             # 60.0/20.0 (hex_size=40 * PHI^1, PHI^-1.5)
			"color": Color(1.0, 0.9, 0.6) if i % 2 == 0 else Color(0.6, 0.4, 0.9),
			"alpha": 0.8,
			"speed": 82.33 + float(i) * 15.28,                                  # 90.0/15.0
			"age": 0.0,
			"life": 0.6854 + float(i) * 0.1,                                    # 0.7/0.1
		})


func _check_battle_end() -> void:
	var white_alive := 0
	for sn in white_army:
		if is_instance_valid(sn) and sn.has_method("get_life_pct") and sn.get_life_pct() > 0.0:
			white_alive += 1
	var black_alive := 0
	for sn in black_army:
		if is_instance_valid(sn) and sn.has_method("get_life_pct") and sn.get_life_pct() > 0.0:
			black_alive += 1
	if white_alive == 0:
		show_flavor("the field falls silent. matter returns to nothing.")
		battle_active = false
	elif black_alive == 0:
		show_flavor("the void recedes. antimatter has spent itself.")
		battle_active = false


func _check_pandora() -> void:
	# Pandora's box opens when enough substance is collected — color enters the world
	if pandora_opened:
		return
	if substance >= pandora_threshold:
		pandora_opened = true
		color_unlocked = true
		campaign_phase = maxi(campaign_phase, 1)
		narrate(L.t("narr_box_opens"))
		show_flavor("PANDORA'S BOX OPENED \u2014 color is substance, and it is here.")
		# Visual: flash the world with color briefly
		_spawn_death_effect(active_body.position if active_body else Vector2(1200, 900), 0)
		# Color the souls
		for sn in white_army + black_army:
			if is_instance_valid(sn) and sn.has_method("_apply_polarity"):
				sn.color_unlocked = true
				sn._apply_polarity()


# ===================================================================
# GRAND COUNCIL — movement locks, the last survivors choose, then Rebirth
# (canon/00-mythos.md act 3; CRITICAL_BRIEF.md §3/§8)
# ===================================================================

func _check_grand_council() -> void:
	if not council_active and battle_active and death_count >= council_threshold:
		council_active = true
		battle_active = false
		narrate(L.t("narr_council"))
		_open_grand_council()


func _open_grand_council() -> void:
	if not council_ui:
		var ui_script = preload("res://scripts/council_ui.gd")
		council_ui = Control.new()
		council_ui.name = "GrandCouncil"
		council_ui.set_script(ui_script)
		council_ui.main_ref = self
		hud.add_child(council_ui)
	council_ui.visible = true


func _resolve_council(choice: String) -> void:
	var dominant: Array = white_army if white_army.size() >= black_army.size() else black_army
	match choice:
		"domination":
			# The world doesn't let a single color persist — a harsher,
			# involuntary tax paid AFTER the choice, on the winning side only.
			_convert_fraction(dominant, 0.3)
		"split":
			# Same total tax as domination's single-side 30%, but voluntary,
			# symmetric, and paid UP FRONT — no post-choice penalty.
			_convert_fraction(white_army, 0.15)
			_convert_fraction(black_army, 0.15)
	# Rebirth, regardless of choice: color reappears (halved, not zeroed),
	# the wreckage of the last age is cleared, and each side gains a feat.
	world_color = int(world_color / 2)
	for rem in neutron_remnants:
		if is_instance_valid(rem):
			rem.queue_free()
	neutron_remnants.clear()
	death_count = 0
	feats_gained += 1
	council_active = false
	battle_active = true
	if council_ui:
		council_ui.visible = false
	narrate(L.t("narr_rebirth"))


func _convert_fraction(army: Array, ratio: float) -> void:
	# Shared helper for both council choices. Which array is "the other" is
	# picked by reference identity (is_same), not content, so this holds
	# even if a near-wiped army's contents momentarily look equal by size.
	var target_army: Array = black_army if is_same(army, white_army) else white_army
	var count: int = int(army.size() * ratio)
	if count <= 0:
		return
	var pool: Array = army.duplicate()
	pool.shuffle()
	for i in range(mini(count, pool.size())):
		var sn: Node2D = pool[i]
		if not is_instance_valid(sn):
			continue
		sn.polarity = 1 - sn.polarity
		if sn.has_method("_apply_polarity"):
			sn._apply_polarity()
		army.erase(sn)
		target_army.append(sn)


func _update_active_body(delta: float) -> void:
	if not active_body or not is_instance_valid(active_body):
		return
	if active_body.has_method("get_life_pct") and active_body.get_life_pct() <= 0.0:
		_check_incarnation()
	if character_sheet and character_sheet.visible:
		character_sheet._refresh()


# ===================================================================
# THE HOURGLASS — Time as trader (CRITICAL_BRIEF.md §11)
# ===================================================================

## Pours all currently-held dust into world_color. The rate isn't flat —
## Time reads the soul's own currently-formed act (the same ∅sentence
## already scored every ~2.5s for the REACT/PURPOSE HUD, engine_form_act()/
## reaction_engine.form_act()/.react()) and prices the trade by its echo:
## a well-resonating soul (high echo, verdict DA) trades up to 1.5x; a
## noisy one (low echo, verdict NE) trades down to 0.5x. This doesn't call
## apply_reaction() — that already runs on its own 2.5s cadence — this is a
## read-only re-score purely to price the pour. No new UI: the soul already
## computes its act automatically from its own strongest genome traits
## (engine_form_act(), "the soul speaks what it is"), so there's nothing
## for the player to compose. Still no Council-pacing cost (death_count
## untouched) — deliberately deferred, see canon/debate-log.md #128.
func _pour_hourglass() -> void:
	if dust <= 0:
		narrate(L.t("narr_hourglass_empty"))
		return
	var poured := dust
	dust = 0
	var echo := 0.0
	if reaction_engine and active_body and active_body.genome and not _reaction_act.is_empty():
		var g = active_body.genome
		var prof: Dictionary = reaction_engine.form_act(g, _reaction_act)
		var r: Dictionary = reaction_engine.react(g, prof)
		echo = r["echo"]
	var multiplier: float = 0.5 + echo  # echo in [0,1] -> rate in [0.5, 1.5]
	var gained: int = int(round(float(poured) * multiplier))
	world_color += gained
	narrate(L.t("narr_hourglass_poured") % [poured, echo, gained])


# ===================================================================
# SOUL VAULT — gumball machine (luck-driven, perception reads odds)
# ===================================================================

func _open_gumball_machine() -> void:
	if not soul_vault or not active_body or not active_body.genome:
		return
	var g: RefCounted = active_body.genome
	if not vault_ui:
		var ui_script = preload("res://scripts/vault_machine_ui.gd")
		vault_ui = Control.new()
		vault_ui.name = "VaultMachine"
		vault_ui.set_script(ui_script)
		hud.add_child(vault_ui)
	# The coin is dust, not upgrade_points — upgrade_points already has its own
	# purpose (soul_genome.gd's 5 ability-upgrade categories), and per the
	# canon debate-log (007), dust is specifically "the character-builder
	# currency". Using upgrade_points here would spend the same treasure twice
	# for two different systems.
	if dust < 1:
		narrate(L.t("narr_no_coin"))
		vault_ui.play_empty()
		return
	dust -= 1
	# WIS is vision, not perception — DESIGN.md documents INT -> perception,
	# WIS -> vision. The odds-reading roll belongs to INT.
	var result: Dictionary = soul_vault.draw_from_machine(1, dust + 1, g.LUK, g.INT)
	if result.get("ok", false):
		var drawn: Dictionary = result["soul"]
		var quality: String = result["quality"]
		var chance: float = result["perceived_chance"]
		vault_ui.play_draw(quality)
		var display := "the machine turns. you drew a %s soul." % quality
		if chance < 0.3:
			display += " (you barely saw the odds)"
		elif chance > 0.7:
			display += " (you read the odds clearly)"
		narrate(display)
		_flavor_from_genome(drawn["genome"])
	else:
		narrate(L.t("narr_machine_empty"))
		vault_ui.play_empty()


func _flavor_from_genome(g: RefCounted) -> void:
	if g.has_method("get_modification_summary"):
		var mods: String = g.get_modification_summary()
		show_flavor("vault holds %s \u2014 %s" % [soul_vault.get_vault_summary(), mods])


# ===================================================================
# VISUAL EFFECTS — bang, waves, death, impact
# ===================================================================

var _effects: Array[Dictionary] = []

func _spawn_death_effect(pos: Vector2, pol: int) -> void:
	# Death burst — circles expanding outward. Re-derived from PHI, hex_size
	# (40.0, already PHI-base-aligned so max_radius's base term is unchanged)
	# as the spatial base (canon/01b-sacred-geometry.md).
	var col := Color(0.8, 0.8, 0.8) if pol == 0 else Color(0.3, 0.3, 0.35)
	for i in 5:
		_effects.append({
			"pos": pos,
			"radius": 4.86 + float(i) * 7.86,       # 5.0/8.0
			"max_radius": 40.0 + float(i) * 15.28,  # 40.0 unchanged (== hex_size), 15.0 -> hex_size*PHI^-2
			"color": col,
			"alpha": 0.6,
			"speed": 64.72 + float(i) * 19.43,      # 60.0/20.0
			"age": 0.0,
			"life": 0.5388 + float(i) * 0.1618,     # 0.6/0.15
		})


func _spawn_beam_impact(pos: Vector2) -> void:
	# Flash when beam hits obstacle. Re-derived from PHI (canon/01b-sacred-geometry.md).
	for i in 3:
		_effects.append({
			"pos": pos,
			"radius": 3.0,
			"max_radius": 19.43 + float(i) * 9.44,  # 20.0/10.0
			"color": Color(1.0, 1.0, 1.0),
			"alpha": 0.8,
			"speed": 82.33,                          # 80.0
			"age": 0.0,
			"life": 0.333,                            # 0.3
		})


func _spawn_force_field_ripple(pos: Vector2) -> void:
	# Dark energy ripple when force field activates. Re-derived from PHI
	# (canon/01b-sacred-geometry.md).
	_effects.append({
		"pos": pos,
		"radius": 10.0,      # == UI_BASE * PHI^0, exact
		"max_radius": 82.33, # 80.0 -> hex_size * PHI^1.5
		"color": Color(0.3, 0.2, 0.5),
		"alpha": 0.4,
		"speed": 104.72,     # 100.0 -> hex_size * PHI^2
		"age": 0.0,
		"life": 0.5388,      # 0.5
	})


func _update_effects(delta: float) -> void:
	for i in range(_effects.size() - 1, -1, -1):
		var e: Dictionary = _effects[i]
		e["age"] += delta
		if e["age"] >= e["life"]:
			_effects.remove_at(i)
		else:
			var progress: float = e["age"] / e["life"]
			e["radius"] += e["speed"] * delta
			e["alpha"] = (1.0 - progress) * 0.6
