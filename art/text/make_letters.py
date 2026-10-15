"""Builds an extruded, bevelled 3D alphabet for in-world sign text (docs/MAP_AND_TEXT_FINDINGS.md, method 1).

Run headless:  blender --background --python art/text/make_letters.py
Writes art/text/letters.fbx (one mesh per glyph, named L_<code>), letters.json (metrics for layout),
and preview.png. Letters stand upright (Roblox Y up), face +Z in Roblox, origin = bounding-box centre.
"""
import json
import math
from pathlib import Path

import bpy
import bmesh
from mathutils import Matrix, Vector

HERE = Path(__file__).parent
FONT = r"C:\Windows\Fonts\seguibl.ttf"  # Segoe UI Black; swap for Fredoka One if it gets installed
CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?'&-"
EXTRUDE = 0.09  # Blender extrudes both ways: total depth 0.18 of the 1.0 em
BEVEL = 0.035
GAP = 1.4

bpy.ops.wm.read_factory_settings(use_empty=True)
font = bpy.data.fonts.load(FONT)
deps = bpy.context.evaluated_depsgraph_get()
stand_up = Matrix.Rotation(math.radians(90), 4, "X")  # text plane XY -> XZ so letters stand on Blender Z

meta = {"font": Path(FONT).name, "glyphs": {}}
baseline_cap = None
for i, ch in enumerate(CHARS):
    curve = bpy.data.curves.new(f"c{ord(ch)}", "FONT")
    curve.body = ch
    curve.font = font
    curve.size = 1.0
    curve.extrude = EXTRUDE
    curve.bevel_depth = BEVEL
    curve.bevel_resolution = 3
    curve.resolution_u = 5
    tmp = bpy.data.objects.new("tmp", curve)
    bpy.context.scene.collection.objects.link(tmp)
    deps = bpy.context.evaluated_depsgraph_get()
    mesh = bpy.data.meshes.new_from_object(tmp.evaluated_get(deps))
    bpy.data.objects.remove(tmp)

    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    xs = [v.co.x for v in mesh.vertices]
    ys = [v.co.y for v in mesh.vertices]
    zs = [v.co.z for v in mesh.vertices]
    cx, cy, cz = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2
    mesh.transform(Matrix.Translation(Vector((-cx, -cy, -cz))))
    mesh.transform(stand_up)
    mesh.update()

    name = f"L_{ord(ch)}"
    obj = bpy.data.objects.new(name, mesh)
    obj.location = (i % 10 * GAP, 0, -(i // 10) * GAP)
    bpy.context.scene.collection.objects.link(obj)
    meta["glyphs"][ch] = {
        "name": name,
        "width": round(max(xs) - min(xs), 4),
        "height": round(max(ys) - min(ys), 4),
        "depth": round(max(zs) - min(zs), 4),
        "centerY": round(cy, 4),  # bbox centre above the baseline, in em
        "advance": round(max(xs) + 0.0, 4),
        "tris": len(mesh.polygons),
    }

space = bpy.data.curves.new("space", "FONT")
space.body = "H H"
space.font = font
meta["spaceWidth"] = 0.28
meta["capHeight"] = meta["glyphs"]["H"]["height"]

bpy.ops.export_scene.fbx(
    filepath=str(HERE / "letters.fbx"),
    use_selection=False,
    object_types={"MESH"},
    apply_unit_scale=True,
    bake_space_transform=False,
    axis_forward="-Z",
    axis_up="Y",
    mesh_smooth_type="FACE",
)
(HERE / "letters.json").write_text(json.dumps(meta, indent=1))

# preview render: a word in the arch style, workbench, flat colours
for o in list(bpy.data.objects):
    o.hide_render = True
x = 0.0
word = "GOOD GAMES"
colors = [(1, 0.79, 0.24, 1), (0.25, 0.64, 0.97, 1), (0.95, 0.33, 0.29, 1), (0.36, 0.79, 0.24, 1)]
for j, ch in enumerate(word):
    if ch == " ":
        x += meta["spaceWidth"]
        continue
    g = meta["glyphs"][ch]
    src = bpy.data.objects[g["name"]]
    o = src.copy()
    o.data = src.data
    o.hide_render = False
    o.location = (x + g["width"] / 2, 0, g["centerY"] + (0.04 if j % 2 else 0))
    o.rotation_euler = (0, math.radians((j % 3 - 1) * 4), 0)
    o.color = colors[j % len(colors)]
    bpy.context.scene.collection.objects.link(o)
    x += g["width"] + 0.06
cam_data = bpy.data.cameras.new("cam")
cam = bpy.data.objects.new("cam", cam_data)
bpy.context.scene.collection.objects.link(cam)
cam.location = (x / 2, -6, 1.6)
cam.rotation_euler = (math.radians(78), 0, math.radians(8))
cam_data.lens = 40
bpy.context.scene.camera = cam
scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "OBJECT"
scene.display.shading.show_cavity = True
scene.display.shading.show_object_outline = True
scene.render.resolution_x, scene.render.resolution_y = 1200, 500
scene.render.filepath = str(HERE / "preview.png")
bpy.ops.render.render(write_still=True)
print("LETTERS OK", len(meta["glyphs"]), "glyphs")
