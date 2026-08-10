import bpy
import math
import random

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


def _setup_sprite_camera_and_lights(ortho_scale: float, key_energy: float = 500.0, rim_energy: float = 200.0) -> None:
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
	# WHITE = electron: smooth, radiant, soft — a light source with no sharp edges.
	clear_scene()
	bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, segments=48, ring_count=32)
	obj = bpy.context.object
	obj.name = "WhiteSoul"
	bpy.ops.object.shade_smooth()
	mat = bpy.data.materials.new("WhiteMat")
	mat.use_nodes = True
	bsdf = mat.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = (0.92, 0.93, 0.98, 1.0)
	bsdf.inputs["Roughness"].default_value = 0.2
	bsdf.inputs["Emission Color"].default_value = (1.0, 0.97, 0.85, 1.0)
	bsdf.inputs["Emission Strength"].default_value = 0.4
	obj.data.materials.append(mat)
	_setup_sprite_camera_and_lights(ortho_scale=2.6)
	_setup_sprite_render("white_soul")
	bpy.ops.render.render(write_still=True)


def render_black_sprite() -> None:
	# BLACK = antimatter: faceted, jagged, angular — a void that fractures light, not a sphere.
	# Kept genuinely dark: low-energy lights, near-zero emission (a hint of color in the
	# facet edges only), so it reads as "dark stone" rather than "bright gem".
	clear_scene()
	bpy.ops.mesh.primitive_ico_sphere_add(radius=1.0, subdivisions=2)
	obj = bpy.context.object
	obj.name = "BlackSoul"
	bpy.ops.object.shade_flat()
	random.seed(7)
	mesh = obj.data
	for v in mesh.vertices:
		n = v.normal.copy()
		disp = random.uniform(0.0, 0.35)
		v.co += n * disp
	mesh.update()
	mat = bpy.data.materials.new("BlackMat")
	mat.use_nodes = True
	bsdf = mat.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = (0.02, 0.02, 0.03, 1.0)
	bsdf.inputs["Roughness"].default_value = 0.75
	bsdf.inputs["Emission Color"].default_value = (0.3, 0.12, 0.45, 1.0)
	bsdf.inputs["Emission Strength"].default_value = 0.08
	obj.data.materials.append(mat)
	_setup_sprite_camera_and_lights(ortho_scale=2.9, key_energy=90.0, rim_energy=40.0)
	_setup_sprite_render("black_soul")
	bpy.ops.render.render(write_still=True)


build_reference_scene()
render_white_sprite()
render_black_sprite()
print("=== SOUL ASSET PIPELINE COMPLETE ===")
print("Sprites: white_soul.png, black_soul.png")
