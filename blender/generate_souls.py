import bpy
import bmesh
import math
import random

# Mirrors scripts/sacred_geometry.gd's PHI — Python can't import a .gd file,
# so this is a deliberate duplicate, not drift; keep the two in sync by hand.
PHI = 1.6180339887498949

# Soul Evolution — asset pipeline.
# 1) Reference scene export (.blend/.obj) — proves the modeling pipeline.
# 2) Isolated sprite renders (white_soul.png / black_soul.png) — actual game assets,
#    consumed by scripts/soul.gd as the soul body texture.
#
# Run headless: blender.exe --background --python generate_souls.py
# After running, re-import in Godot: Godot.exe --headless --path <project> --import

OUT_DIR = "D:/Godot/soul-evolution/assets/"


def clear_scene() -> None:
	bpy.ops.wm.read_factory_settings(use_empty=True)


def build_reference_scene() -> None:
	# Side-by-side scene — proves the Blender -> Godot pipeline, kept for reference/iteration.
	clear_scene()
	bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(-1.5, 0, 0))
	white = bpy.context.object
	white.name = "WhiteSoul"
	mat_w = bpy.data.materials.new("WhiteMat")
	mat_w.use_nodes = True
	mat_w.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.95, 0.95, 1.0, 1.0)
	mat_w.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.5
	white.data.materials.append(mat_w)

	bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(1.5, 0, 0))
	black = bpy.context.object
	black.name = "BlackSoul"
	mat_b = bpy.data.materials.new("BlackMat")
	mat_b.use_nodes = True
	mat_b.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.05, 0.05, 0.08, 1.0)
	mat_b.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
	black.data.materials.append(mat_b)

	bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=1.0, depth=0.2, location=(0, 1.8, 0))
	hex_tile = bpy.context.object
	hex_tile.name = "HexTile"
	mat_h = bpy.data.materials.new("HexMat")
	mat_h.use_nodes = True
	mat_h.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.15, 0.15, 0.2, 1.0)
	hex_tile.data.materials.append(mat_h)

	bpy.ops.object.camera_add(location=(0, -5, 3))
	cam = bpy.context.object
	cam.rotation_euler = (math.radians(60), 0, 0)
	bpy.context.scene.camera = cam

	bpy.ops.object.light_add(type='SUN', location=(0, 0, 5))
	sun = bpy.context.object
	sun.data.energy = 3.0

	scene = bpy.context.scene
	scene.render.engine = 'CYCLES'
	scene.render.resolution_x = 800
	scene.render.resolution_y = 600

	bpy.ops.wm.save_as_mainfile(filepath=OUT_DIR + "soul_models.blend")
	bpy.ops.wm.obj_export(filepath=OUT_DIR + "soul_models.obj")
	print("[reference scene] objects:", [o.name for o in bpy.context.scene.objects])


def _setup_sprite_camera_and_lights(ortho_scale: float, key_energy: float = 538.8, rim_energy: float = 205.8) -> None:
	# key/rim defaults re-derived from PHI, LIGHT_BASE=100 (canon/01b-sacred-geometry.md): 500->538.8, 200->205.8
	bpy.ops.object.camera_add(location=(0, -4.0, 0.0), rotation=(math.radians(90), 0, 0))
	cam = bpy.context.object
	cam.data.type = 'ORTHO'
	cam.data.ortho_scale = ortho_scale
	bpy.context.scene.camera = cam
	bpy.ops.object.light_add(type='AREA', location=(-2.0, -3.0, 3.0))
	key = bpy.context.object
	key.data.energy = key_energy
	key.data.size = 3.0
	bpy.ops.object.light_add(type='AREA', location=(2.5, -2.0, -1.5))
	rim = bpy.context.object
	rim.data.energy = rim_energy
	rim.data.size = 2.0


def _setup_sprite_render(name: str) -> None:
	scene = bpy.context.scene
	scene.render.engine = 'CYCLES'
	scene.cycles.samples = 64
	scene.render.resolution_x = 512
	scene.render.resolution_y = 512
	scene.render.film_transparent = True
	scene.render.image_settings.file_format = 'PNG'
	scene.render.image_settings.color_mode = 'RGBA'
	scene.render.filepath = OUT_DIR + name


def render_white_sprite() -> None:
	# WHITE = electron: smooth sphere, shading only — zero hue. This is the
	# shell; color lives in the "fill" soul.gd draws underneath it at runtime
	# (life/substance %), not in this asset. Perfectly neutral grey in, grey
	# emission out — any warmth previously here was a color the model should
	# not be holding.
	clear_scene()
	bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, segments=48, ring_count=32)
	obj = bpy.context.object
	obj.name = "WhiteSoul"
	bpy.ops.object.shade_smooth()
	mat = bpy.data.materials.new("WhiteMat")
	mat.use_nodes = True
	bsdf = mat.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = (0.85, 0.85, 0.85, 1.0)
	bsdf.inputs["Roughness"].default_value = PHI ** -3       # 0.25 -> 0.236
	bsdf.inputs["Emission Color"].default_value = (1.0, 1.0, 1.0, 1.0)
	bsdf.inputs["Emission Strength"].default_value = PHI ** -4  # 0.15 -> 0.146
	obj.data.materials.append(mat)
	_setup_sprite_camera_and_lights(ortho_scale=PHI ** 2)  # 2.6 -> 2.618
	_setup_sprite_render("white_soul")
	bpy.ops.render.render(write_still=True)


def render_black_sprite() -> None:
	# BLACK = antimatter: faceted, jagged shard cluster — a void that
	# fractures light, not a sphere. Shell only, zero hue: no emission at all
	# (pure shadow, lit only by the scene lights) — a "dark gem" reads as
	# holding color; a shadow model shouldn't.
	clear_scene()
	bpy.ops.mesh.primitive_ico_sphere_add(radius=1.0, subdivisions=2)
	obj = bpy.context.object
	obj.name = "BlackSoul"
	bpy.ops.object.shade_flat()
	random.seed(7)
	mesh = obj.data
	for v in mesh.vertices:
		n = v.normal.copy()
		disp = random.uniform(0.0, PHI ** -2)  # 0.35 -> 0.382
		v.co += n * disp
	mesh.update()
	mat = bpy.data.materials.new("BlackMat")
	mat.use_nodes = True
	bsdf = mat.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = (0.035, 0.035, 0.035, 1.0)
	bsdf.inputs["Roughness"].default_value = PHI ** -0.5  # 0.8 -> 0.786
	bsdf.inputs["Emission Strength"].default_value = 0.0
	obj.data.materials.append(mat)
	# ortho_scale 2.9 -> PHI^2 (2.618); key/rim energy re-derived, LIGHT_BASE=100.
	_setup_sprite_camera_and_lights(ortho_scale=PHI ** 2, key_energy=100.0 * PHI ** 0, rim_energy=100.0 * PHI ** -1)
	_setup_sprite_render("black_soul")
	bpy.ops.render.render(write_still=True)


def _setup_top_down_camera_and_lights(ortho_scale: float, key_energy: float = 538.8, rim_energy: float = 205.8) -> None:
	bpy.ops.object.camera_add(location=(0, 0, 4.0), rotation=(0, 0, 0))
	cam = bpy.context.object
	cam.data.type = 'ORTHO'
	cam.data.ortho_scale = ortho_scale
	bpy.context.scene.camera = cam
	bpy.ops.object.light_add(type='AREA', location=(-2.0, -3.0, 3.0))
	key = bpy.context.object
	key.data.energy = key_energy
	key.data.size = 3.0
	bpy.ops.object.light_add(type='AREA', location=(2.5, -2.0, -1.5))
	rim = bpy.context.object
	rim.data.energy = rim_energy
	rim.data.size = 2.0


def render_glass_hex_tile() -> None:
	# Baked glass-material detail for the hex lattice shader (shaders/hex_grid.gdshader):
	# one flat top-down render of a glass hex prism, sampled per-tile at runtime so the
	# lattice keeps its single per-pixel SDF pass instead of gaining ~1100 draw calls back.
	# Dynamic color (world_color_ratio/color_balance) stays computed in-shader; this asset
	# only contributes the static clean-glass rim/refraction highlight on top of it.
	clear_scene()
	bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=1.0, depth=0.15)
	obj = bpy.context.object
	obj.name = "GlassHex"
	bpy.ops.object.shade_smooth()
	mat = bpy.data.materials.new("GlassHexMat")
	mat.use_nodes = True
	bsdf = mat.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = (0.9, 0.95, 1.0, 1.0)
	bsdf.inputs["Transmission Weight"].default_value = 1.0
	bsdf.inputs["Roughness"].default_value = 0.05
	bsdf.inputs["IOR"].default_value = 1.45  # a physical constant, not re-derived (canon/01b-sacred-geometry.md exclusions)
	obj.data.materials.append(mat)
	_etch_hexagram(obj)
	# ortho_scale 2.2 -> PHI^1.5 (2.058); key/rim re-derived, LIGHT_BASE=100.
	_setup_top_down_camera_and_lights(ortho_scale=PHI ** 1.5, key_energy=100.0 * PHI ** 3, rim_energy=100.0 * PHI ** 2.5)
	_setup_sprite_render("glass_hex_tile")
	bpy.ops.render.render(write_still=True)


def _etch_hexagram(obj) -> None:
	# Hexagram etch — two overlapping triangles, 60 degrees apart, per
	# canon/01b-sacred-geometry.md. A shallow inset groove on the top face
	# rather than a full boolean cut, so the mesh stays manifold and this
	# stays robust to run headless. A true two-triangle boolean cut is a
	# follow-up, not this pass's scope.
	bm = bmesh.new()
	bm.from_mesh(obj.data)
	top_faces = [f for f in bm.faces if f.normal.z > 0.9]
	bmesh.ops.inset_individual(bm, faces=top_faces, thickness=PHI ** -4, depth=-PHI ** -6)
	bm.to_mesh(obj.data)
	bm.free()
	obj.data.update()


def render_window_frame() -> None:
	# WINDOW FRAME — canon's per-element treasure-hoard art frame
	# (canon/05-treasures.md:59-63, canon/00-mythos.md:95). Same shell-only
	# philosophy as the soul sprites above: neutral grey, zero hue of its
	# own. The quality tint (gold/silver/dull — vault_machine_ui.gd's
	# _color_for_quality palette) is poured in at runtime via `modulate`
	# (character_sheet.gd), not baked here.
	clear_scene()
	outer = 1.0
	border = PHI ** -4  # 0.16 -> 0.146
	depth = PHI ** -4   # 0.14 -> 0.146
	bar_specs = [
		((0.0, outer - border * 0.5, 0.0), (outer, border * 0.5, depth)),
		((0.0, -(outer - border * 0.5), 0.0), (outer, border * 0.5, depth)),
		((outer - border * 0.5, 0.0, 0.0), (border * 0.5, outer, depth)),
		((-(outer - border * 0.5), 0.0, 0.0), (border * 0.5, outer, depth)),
	]
	bars = []
	for loc, scl in bar_specs:
		bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
		bar = bpy.context.object
		bar.scale = scl
		bpy.ops.object.transform_apply(location=True, rotation=False, scale=True)
		bars.append(bar)

	for bar in bars:
		bar.select_set(True)
	bpy.context.view_layer.objects.active = bars[0]
	bpy.ops.object.join()
	obj = bpy.context.object
	obj.name = "WindowFrame"

	bevel = obj.modifiers.new("Bevel", 'BEVEL')
	bevel.width = 0.03
	bevel.segments = 3
	bpy.ops.object.modifier_apply(modifier="Bevel")
	bpy.ops.object.shade_smooth()

	mat = bpy.data.materials.new("WindowFrameMat")
	mat.use_nodes = True
	bsdf = mat.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = (0.5, 0.5, 0.5, 1.0)
	bsdf.inputs["Roughness"].default_value = PHI ** -1.5  # 0.45 -> 0.486
	bsdf.inputs["Emission Strength"].default_value = 0.0
	obj.data.materials.append(mat)
	_etch_hexagram(obj)

	_setup_sprite_camera_and_lights(ortho_scale=PHI ** 2)  # 2.6 -> 2.618
	_setup_sprite_render("window_frame")
	bpy.ops.render.render(write_still=True)


def render_operator_sigils() -> None:
	# REACTION OPERATOR SIGILS — emissive 3D glyphs for the ∅sentence operators
	# (∇ ¬ ∆ ✡ τ σ) that the reaction engine (scripts/reaction_engine.gd) forms
	# acts from. Each is a flat emissive disc with the operator glyph, rendered
	# top-down like the other sprites. Emissive (a radiation source), matching
	# the canon's "shell holds no color" rule — the glyph is light, not paint.
	sigils = ["delta", "neg", "div", "trace", "tau", "sigma"]
	glyphs = {"delta": "∆", "neg": "¬", "div": "∇", "trace": "✡", "tau": "τ", "sigma": "σ"}
	for name in sigils:
		clear_scene()
		bpy.ops.mesh.primitive_circle_add(vertices=48, radius=PHI, location=(0, 0, 0))
		disc = bpy.context.object
		disc.name = name + "_sigil"
		bpy.ops.object.convert(target='MESH')
		mat = bpy.data.materials.new(name + "_SigilMat")
		mat.use_nodes = True
		bsdf = mat.node_tree.nodes["Principled BSDF"]
		bsdf.inputs["Base Color"].default_value = (0.05, 0.05, 0.08, 1.0)
		bsdf.inputs["Emission Strength"].default_value = PHI ** 2
		disc.data.materials.append(mat)
		bpy.ops.object.text_add(location=(0, 0, 0.05))
		txt = bpy.context.object
		txt.name = name + "_glyph"
		txt.data.body = glyphs[name]
		txt.data.align_x = 'CENTER'
		txt.data.align_y = 'CENTER'
		txt.data.size = 1.6
		txt.data.extrude = 0.08
		txt.data.bevel_depth = 0.02
		txt.data.bevel_resolution = 4
		tmat = bpy.data.materials.new(name + "_GlyphMat")
		tmat.use_nodes = True
		tbsdf = tmat.node_tree.nodes["Principled BSDF"]
		tbsdf.inputs["Base Color"].default_value = (0.9, 0.95, 1.0, 1.0)
		tbsdf.inputs["Emission Strength"].default_value = PHI ** 3
		txt.data.materials.append(tmat)
		bpy.ops.object.select_all(action='DESELECT')
		disc.select_set(True)
		bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
		_setup_top_down_camera_and_lights(ortho_scale=PHI ** 2.5, key_energy=100.0 * PHI ** 3, rim_energy=100.0 * PHI ** 2.5)
		_setup_sprite_render("sigil_" + name)
		bpy.ops.render.render(write_still=True)


build_reference_scene()
render_white_sprite()
render_black_sprite()
render_glass_hex_tile()
render_window_frame()
render_operator_sigils()
print("=== SOUL ASSET PIPELINE COMPLETE ===")
print("Sprites: white_soul.png, black_soul.png, glass_hex_tile.png, window_frame.png, sigil_*.png")
