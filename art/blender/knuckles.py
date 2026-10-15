"""Knuckle dusters for Break The Walls, built in Blender to match the hotbar icons and fit the R15 hand.

Run headless:  "C:/Program Files/Blender Foundation/Blender 5.1/blender.exe" -b -P art/blender/knuckles.py [-- Tier ...]
Writes to Desktop/Break The Walls/blender/:
  Knuckles_<Tier>.fbx / .glb   the duster only, one mesh per material (named <Tier>_<Material>)
  preview_<Tier>.png           Cycles render on the real hand block, from the icon's angle
  knuckles.blend, knuckles_spec.txt, knuckles_colours.json (Roblox Color/Material per mesh for the wiring script)

Units: 1 Blender unit = 1 stud. Blender X = hand X (width), Blender Y = -hand Z (so +Y = the hand's front, where
spikes point "up" in these models), Blender Z = hand Y (along the arm). The R15 RightHand measured in Play
(2026-10-15) is 1.042 x 0.317 x 1.204 studs; its punching end is hand -Y = Blender -Z. Everything sits on that
end face, sized to its width, like the icons (art/icons/fist_1..5.png). The duster's origin is the hand centre,
so the weld C0 is CFrame.identity; scale (0.88, 1.1, 0.88) for the first-person copy on Camera.ViewModel.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

OUT = Path.home() / "Desktop" / "Break The Walls" / "blender"
OUT.mkdir(parents=True, exist_ok=True)

HAND = (1.042, 1.204, 0.317)
Z0 = -HAND[2] / 2  # the punching face
FX = (-0.45, -0.15, 0.15, 0.45)  # four knuckle positions across the face (duster runs a bit wider than the hand)

COLOURS = {}  # tier -> {mesh name: {"color": [r,g,b] 0-255, "material": Roblox material}}


# ---------- materials ----------
def mat(name, rgb, metal=0.0, rough=0.4, emit=0.0, glass=0.0, coat=0.5, roblox="SmoothPlastic"):
    m = bpy.data.materials.new(name)
    nt = m.node_tree
    p = nt.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value = (*rgb, 1)
    p.inputs["Metallic"].default_value = metal
    p.inputs["Roughness"].default_value = rough
    p.inputs["Coat Weight"].default_value = coat
    if glass:
        p.inputs["Transmission Weight"].default_value = glass
        p.inputs["IOR"].default_value = 1.6
    if emit:
        p.inputs["Emission Color"].default_value = (*rgb, 1)
        p.inputs["Emission Strength"].default_value = emit
    m.diffuse_color = (*rgb, 1)
    m["roblox"] = roblox
    return m


# ---------- primitives (all return the object, already linked to coll) ----------
def _take(name, m, coll, smooth=True, bevel=0.0, seg=3):
    o = bpy.context.active_object
    o.name = name
    for c in list(o.users_collection):
        c.objects.unlink(o)
    coll.objects.link(o)
    o.data.materials.append(m)
    if bevel:
        b = o.modifiers.new("Bevel", "BEVEL")
        b.width, b.segments, b.limit_method = bevel, seg, "ANGLE"
    if smooth:
        o.data.shade_smooth()
        if bevel:
            o.modifiers.new("WN", "WEIGHTED_NORMAL").keep_sharp = True
    return o


def box(name, size, loc, m, coll, bevel=0.03, seg=4, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return _take(name, m, coll, bevel=bevel, seg=seg)


def torus(name, loc, R, r, m, coll, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=40, minor_segments=16,
                                     location=loc, rotation=rot)
    return _take(name, m, coll)


def cone(name, loc, r, depth, m, coll, rot=(0, 0, 0), verts=16, smooth=True):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=0, depth=depth, location=loc, rotation=rot)
    return _take(name, m, coll, smooth=smooth)


def gem(name, loc, size, m, coll, squash=(1, 1, 0.6)):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=size, location=loc)
    o = bpy.context.active_object
    o.scale = squash
    bpy.ops.object.transform_apply(scale=True)
    return _take(name, m, coll, smooth=False)


def dome(name, loc, r, m, coll, flat=0.5):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=r, location=loc)
    o = bpy.context.active_object
    o.scale = (1, 1, flat)
    bpy.ops.object.transform_apply(scale=True)
    return _take(name, m, coll)


def bolt(name, pts, r, m, coll):
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = r
    cu.bevel_resolution = 2
    sp = cu.splines.new("POLY")
    sp.points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        sp.points[i].co = (*p, 1)
    o = bpy.data.objects.new(name, cu)
    coll.objects.link(o)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.convert(target="MESH")
    o = bpy.context.active_object
    o.data.materials.append(m)
    return o


def bend(o, angle):
    d = o.modifiers.new("Bend", "SIMPLE_DEFORM")
    d.deform_method, d.deform_axis, d.angle = "BEND", "Y", math.radians(angle)
    return o


# ---------- tiers ----------
def bronze(c):
    cu = mat("Copper", (0.78, 0.30, 0.10), metal=1, rough=0.18, roblox="Metal")
    dk = mat("CopperDark", (0.45, 0.16, 0.06), metal=1, rough=0.3, roblox="Metal")
    # four fat rings standing on the face, holes facing forward like the icon
    for i, x in enumerate(FX):
        torus(f"Ring{i}", (x, 0.17, Z0 - 0.08), 0.135, 0.055, cu, c)
    # the thick rounded grip bar across the lower half, in front of the rings
    box("Bar", (1.46, 0.30, 0.26), (0, -0.11, Z0 - 0.18), cu, c, bevel=0.09, seg=5)
    box("BarEdge", (1.34, 0.05, 0.18), (0, -0.27, Z0 - 0.18), dk, c, bevel=0.02)
    box("Backplate", (1.2, 0.5, 0.05), (0, 0.05, Z0 - 0.02), dk, c, bevel=0.02)


def iron(c):
    st = mat("Steel", (0.80, 0.82, 0.86), metal=1, rough=0.22, roblox="Metal")
    ch = mat("Chrome", (0.95, 0.96, 0.98), metal=1, rough=0.06, roblox="Metal")
    dk = mat("Gunmetal", (0.30, 0.32, 0.36), metal=1, rough=0.35, roblox="Metal")
    box("Plate", (1.36, 0.34, 0.10), (0, 0, Z0 - 0.07), st, c, bevel=0.025)
    box("Spine", (1.22, 0.22, 0.06), (0, 0, Z0 - 0.02), dk, c, bevel=0.015)
    for i, x in enumerate(FX):  # four cone spikes out of the plate
        cone(f"Spike{i}", (x, 0, Z0 - 0.22), 0.085, 0.22, ch, c, rot=(math.pi, 0, 0))
        dome(f"SpikeBase{i}", (x, 0, Z0 - 0.12), 0.1, dk, c, flat=0.35)
    for i, x in enumerate((-0.6, -0.3, 0, 0.3, 0.6)):  # rivet rows top and bottom
        for j, y in enumerate((0.12, -0.12)):
            dome(f"Rivet{i}_{j}", (x, y, Z0 - 0.12), 0.028, ch, c, flat=0.6)
    for s in (-1, 1):  # pointed end caps
        box(f"Cap{s}", (0.07, 0.40, 0.16), (s * 0.70, 0, Z0 - 0.07), dk, c, bevel=0.02)
        cone(f"CapSpike{s}", (s * 0.84, 0, Z0 - 0.07), 0.08, 0.22, ch, c, rot=(0, s * math.pi / 2, 0))


def gold(c):
    au = mat("Gold", (1.0, 0.52, 0.04), metal=1, rough=0.14, roblox="Metal")
    au2 = mat("GoldBright", (1.0, 0.70, 0.15), metal=1, rough=0.08, roblox="Metal")
    ru = mat("Ruby", (0.9, 0.02, 0.06), rough=0.03, glass=0.4, emit=0.15, coat=1, roblox="Glass")
    # layered like the icon: ring ridges wrap the knuckles at the back, the band sits in front, the ruby on top
    for i, x in enumerate(FX):
        torus(f"Ridge{i}", (x, 0, Z0 + 0.12), 0.30, 0.06, au2, c, rot=(0, math.pi / 2, 0))
    box("Band", (1.42, 0.40, 0.16), (0, 0, Z0 - 0.17), au, c, bevel=0.07, seg=5)
    box("BandLip", (1.30, 0.46, 0.06), (0, 0, Z0 - 0.10), au2, c, bevel=0.025)
    box("Bezel", (0.34, 0.34, 0.08), (0, 0, Z0 - 0.27), au2, c, bevel=0.03, rot=(0, 0, math.pi / 4))
    gem("Ruby", (0, 0, Z0 - 0.33), 0.17, ru, c, squash=(1, 1, 0.55))
    for i in range(4):  # prongs
        a = i * math.pi / 2
        dome(f"Prong{i}", (math.cos(a) * 0.19, math.sin(a) * 0.19, Z0 - 0.31), 0.035, au2, c, flat=1)
    for s_ in (-1, 1):
        gem(f"SideGem{s_}", (s_ * 0.52, 0, Z0 - 0.26), 0.06, ru, c)


def diamond(c):
    cr = mat("Crystal", (0.05, 0.80, 0.95), rough=0.1, glass=0.2, emit=0.25, coat=1, roblox="Glass")
    core = mat("CrystalCore", (0.55, 1.0, 1.0), rough=0.02, emit=1.2, roblox="Neon")
    frame = mat("Frost", (0.85, 0.97, 1.0), metal=0.6, rough=0.15, roblox="Metal")
    box("Frame", (1.40, 0.36, 0.06), (0, 0, Z0 - 0.03), frame, c, bevel=0.02)
    for i, x in enumerate(FX):  # four crystal blocks, each with an inset gem
        box(f"Block{i}", (0.29, 0.32, 0.17), (x, 0, Z0 - 0.14), cr, c, bevel=0.05, seg=1)
        gem(f"Core{i}", (x, 0, Z0 - 0.23), 0.075, core, c)
        cone(f"Spike{i}", (x, 0.30, Z0 - 0.14), 0.085, 0.30, cr, c, rot=(-math.pi / 2, 0, 0), verts=4, smooth=False)
    for s in (-1, 1):
        cone(f"SideSpike{s}", (s * 0.86, 0, Z0 - 0.14), 0.09, 0.28, cr, c, rot=(0, s * math.pi / 2, 0), verts=4,
             smooth=False)


def energy(c):
    nv = mat("Navy", (0.06, 0.10, 0.55), metal=0.4, rough=0.18, roblox="SmoothPlastic")
    glow = mat("Electric", (0.40, 0.75, 1.0), emit=6.0, roblox="Neon")
    blade = mat("Blade", (0.15, 0.28, 0.95), metal=0.5, rough=0.12, emit=0.15, roblox="SmoothPlastic")
    box("Core", (1.38, 0.34, 0.18), (0, 0, Z0 - 0.12), nv, c, bevel=0.03)
    edge = box("Edge", (1.40, 0.36, 0.20), (0, 0, Z0 - 0.12), glow, c, bevel=0.0)
    w = edge.modifiers.new("Wire", "WIREFRAME")
    w.thickness = 0.028
    for i, x in enumerate(FX):  # glowing rings wrapping the knuckles
        torus(f"Ring{i}", (x, 0, Z0 + 0.02), 0.25, 0.035, blade, c, rot=(0, math.pi / 2, 0))
        torus(f"RingGlow{i}", (x, 0, Z0 + 0.02), 0.25, 0.022, glow, c, rot=(0, math.pi / 2, 0))
        cone(f"Spike{i}", (x, 0.36, Z0 - 0.12), 0.08, 0.40, blade, c, rot=(-math.pi / 2, 0, 0), verts=4, smooth=False)
    for s in (-1, 1):
        cone(f"SideBlade{s}", (s * 0.90, 0, Z0 - 0.12), 0.12, 0.36, blade, c, rot=(0, s * math.pi / 2, 0), verts=4,
             smooth=False)
    zz = Z0 - 0.215  # lightning across the front face
    bolt("Bolt1", [(-0.62, 0.10, zz), (-0.35, -0.02, zz), (-0.25, 0.08, zz), (0.05, -0.10, zz), (0.12, 0.0, zz),
                   (0.40, -0.12, zz)], 0.014, glow, c)
    bolt("Bolt2", [(0.15, 0.13, zz), (0.32, 0.03, zz), (0.42, 0.10, zz), (0.62, -0.06, zz)], 0.012, glow, c)


TIERS = {"Bronze": bronze, "Iron": iron, "Gold": gold, "Diamond": diamond, "Energy": energy}


# ---------- scene, render, export ----------
def merge_by_material(coll, tier):
    """Apply modifiers, then join meshes per material so Roblox gets one MeshPart per colour."""
    groups = {}
    for o in list(coll.objects):
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        for m in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)
        groups.setdefault(o.data.materials[0].name, []).append(o)
    out = {}
    for mname, objs in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        o = bpy.context.active_object
        o.name = o.data.name = f"{tier}_{mname}"
        m = o.data.materials[0]
        rgb = [round(v * 255) for v in m.diffuse_color[:3]]
        out[o.name] = {"color": rgb, "material": m.get("roblox", "SmoothPlastic")}
    return out


def setup_render():
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 96
    sc.cycles.use_denoising = True
    sc.render.resolution_x = sc.render.resolution_y = 900
    sc.view_settings.view_transform = "AgX"
    try:
        sc.view_settings.look = "AgX - Punchy"
    except TypeError:
        pass
    w = bpy.data.worlds.new("W")
    w.color = (0.78, 0.84, 0.92)
    nt = w.node_tree
    nt.nodes["Background"].inputs[0].default_value = (0.78, 0.84, 0.92, 1)
    nt.nodes["Background"].inputs[1].default_value = 0.55
    sc.world = w
    for name, loc, energy, size in (("Key", (-3, 3, -4), 220, 3), ("Rim", (3, 2, 2), 160, 2), ("Fill", (2, -3, -3), 70, 4)):
        L = bpy.data.lights.new(name, "AREA")
        L.energy, L.size = energy, size
        o = bpy.data.objects.new(name, L)
        o.location = loc
        o.rotation_euler = (-Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        sc.collection.objects.link(o)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    cam.data.lens = 70
    sc.collection.objects.link(cam)
    sc.camera = cam
    return cam


def aim(cam, loc, target, up=(0, 1, 0)):
    """Point the camera at target with image-up along `up` (+Y = the hand's front, like the icons' finger tops)."""
    from mathutils import Matrix
    f = (Vector(target) - Vector(loc)).normalized()
    r = f.cross(Vector(up)).normalized()
    u = r.cross(f)
    cam.location = loc
    cam.matrix_world = Matrix((
        (r.x, u.x, -f.x, loc[0]),
        (r.y, u.y, -f.y, loc[1]),
        (r.z, u.z, -f.z, loc[2]),
        (0, 0, 0, 1),
    ))


def main():
    want = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(TIERS)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    cam = setup_render()
    sc = bpy.context.scene
    # the real hand block plus a stub of forearm, preview only (never exported)
    ref = bpy.data.collections.new("Hand_Reference")
    sc.collection.children.link(ref)
    skin = mat("Skin", (0.92, 0.66, 0.10), rough=0.5, coat=0.2)
    sleeve = mat("Sleeve", (0.12, 0.12, 0.14), rough=0.6)
    box("Hand", HAND, (0, 0, 0), skin, ref, bevel=0.03)
    box("Forearm", (1.10, 1.10, 1.4), (0, 0, HAND[2] / 2 + 0.7), sleeve, ref, bevel=0.03)
    colls = {}
    for tier in TIERS:
        c = bpy.data.collections.new(f"Knuckles_{tier}")
        sc.collection.children.link(c)
        TIERS[tier](c)
        colls[tier] = c
    spec = ["Knuckle dusters, built to the R15 hand (1.042 x 0.317 x 1.204 studs), matching art/icons/fist_1..5.", ""]
    for tier, c in colls.items():
        COLOURS[tier] = merge_by_material(c, tier)
    for tier, c in colls.items():
        if tier not in want:
            continue
        for t2, c2 in colls.items():
            c2.hide_render = t2 != tier
        # the icon's angle: knuckle face towards the viewer, from the left and a little above
        aim(cam, (1.1, 1.5, -3.3), (0, 0.05, -0.2))
        sc.render.filepath = str(OUT / f"preview_{tier}.png")
        bpy.ops.render.render(write_still=True)
        # export: this tier's meshes only
        bpy.ops.object.select_all(action="DESELECT")
        for o in c.objects:
            o.select_set(True)
        bpy.ops.export_scene.fbx(filepath=str(OUT / f"Knuckles_{tier}.fbx"), use_selection=True, axis_forward="-Z",
                                 axis_up="Y", object_types={"MESH"}, mesh_smooth_type="FACE", apply_unit_scale=True)
        bpy.ops.export_scene.gltf(filepath=str(OUT / f"Knuckles_{tier}.glb"), use_selection=True, export_yup=True)
        lo = [min((o.matrix_world @ v.co)[k] for o in c.objects for v in o.data.vertices) for k in range(3)]
        hi = [max((o.matrix_world @ v.co)[k] for o in c.objects for v in o.data.vertices) for k in range(3)]
        tris = sum(len(p.vertices) - 2 for o in c.objects for p in o.data.polygons)
        spec.append(f"Knuckles_{tier}: {len(c.objects)} meshes, {tris} tris, Roblox bounds X {lo[0]:.2f}..{hi[0]:.2f} "
                    f"Y {lo[2]:.2f}..{hi[2]:.2f} Z {-hi[1]:.2f}..{-lo[1]:.2f} (hand centre = 0,0,0)")
    for c in colls.values():
        c.hide_render = False
    spec += ["", "Origin = the hand's centre, so weld each mesh to RightHand with C0 = CFrame.identity (the meshes keep",
             "their offsets if imported as one Model with 'Keep model pivot / world position' on).",
             "Colours/materials per mesh: knuckles_colours.json. First-person copy: scale by (0.88, 1.1, 0.88).",
             "Spikes on Diamond/Energy point toward the hand's front (-Z in Roblox hand space); turn 180 deg if wrong."]
    (OUT / "knuckles_spec.txt").write_text("\n".join(spec) + "\n", encoding="utf-8")
    (OUT / "knuckles_colours.json").write_text(json.dumps(COLOURS, indent=1), encoding="utf-8")
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "knuckles.blend"))
    print("DONE", ", ".join(want))


main()
