"""Generate Godot .tscn files for the Train Rush station from the Unity scenes.

Run from anywhere: python tools/unity_port/gen_godot.py (needs pyyaml and numpy).
It overwrites the scenes listed in PREFAB_SCENES, scenes/station/station.tscn and
scenes/levels/lvl_game.tscn, so hand edits to those files are lost on the next run.

Unity is left-handed, Godot right-handed: every Unity transform is conjugated by Mz = diag(1, 1, -1).
Unity mirrors FBX geometry on X when importing, so FBX meshes/models also get F = diag(-1, 1, -1)
(a 180 degree turn around Y) on the right.
"""
import os
import re
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import unity_scene as us  # noqa: E402

GODOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
UNITY = os.path.join(GODOT, "unity", "TrainRush")
MZ = np.diag([1.0, 1.0, -1.0, 1.0])
F = np.diag([-1.0, 1.0, -1.0, 1.0])

KITS = {"kenney_train-kit": "kenney_train_kit", "kenney_mini-market": "kenney_mini_market",
        "kenney_mini-characters": "kenney_mini_characters", "kenney_prototype-kit": "kenney_prototype_kit"}
# Submeshes Unity places on their own (fileID -> saved mesh)
SPLIT_MESHES = {
    ("door-sliding-double.fbx", "-3086061465205573400"): "res://assets/models/kenney_prototype_kit/door_sliding_double_left.res",
    ("door-sliding-double.fbx", "5688017428630502997"): "res://assets/models/kenney_prototype_kit/door_sliding_double_right.res",
    ("TrafficLight.fbx", "-7282722144640355078"): "res://assets/models/props/traffic_light_black.res",
    ("TrafficLight.fbx", "5249937882936121925"): "res://assets/models/props/traffic_light_green.res",
    ("TrafficLight.fbx", "-2267269527571904676"): "res://assets/models/props/traffic_light_red.res",
    ("TrafficLight.fbx", "5197013329869976131"): "res://assets/models/props/traffic_light_yellow.res",
}
MATERIALS = {"MAT_Wall.mat": "res://assets/materials/mat_wall.tres",
             "MAT_Ground.mat": "res://assets/materials/mat_ground.tres",
             "MAT_Roof.mat": "res://assets/materials/mat_roof.tres",
             "MAT_TrafficLightBase.mat": "res://assets/materials/mat_traffic_light_base.tres",
             "MAT_TrafficLightGreen.mat": "res://assets/materials/mat_traffic_light_green.tres",
             "MAT_TrafficLightRed.mat": "res://assets/materials/mat_traffic_light_red.tres",
             "MAT_TrafficLightYellow.mat": "res://assets/materials/mat_traffic_light_yellow.tres"}
PREFAB_SCENES = {
    "Assets/Level/Prefabs/Environment/Fence.prefab": "res://scenes/environment/fence.tscn",
    "Assets/Level/Prefabs/Environment/Cash Register.prefab": "res://scenes/environment/cash_register.tscn",
    "Assets/Level/Prefabs/Environment/Floor Markings Boarding.prefab":
        "res://scenes/environment/floor_markings_boarding.tscn",
    "Assets/Level/Prefabs/Environment/Entrance Gate.prefab": "res://scenes/environment/entrance_gate.tscn",
    "Assets/Level/Prefabs/Environment/Double Door.prefab": "res://scenes/environment/double_door.tscn",
    "Assets/Level/Prefabs/Environment/Railroad.prefab": "res://scenes/environment/railroad.tscn",
}
for _i in range(1, 8):
    PREFAB_SCENES["Assets/Level/Prefabs/TrainsModels/Train Model %d.prefab" % _i] = \
        "res://scenes/train/models/train_model_%d.tscn" % _i
    PREFAB_SCENES["Assets/Level/Prefabs/WagonsModels/Wagon Model %d.prefab" % _i] = \
        "res://scenes/train/models/wagon_model_%d.tscn" % _i
SCRIPTS = {
    "station": "res://scripts/station/station.gd",
    "boarding": "res://scripts/station/boarding.gd",
    "wagon_queue": "res://scripts/station/wagon_queue.gd",
    "spawner": "res://scripts/passengers/passenger_spawner.gd",
    "camera": "res://scripts/camera/camera_follow.gd",
    "revenue": "res://scripts/progression/passenger_revenue.gd",
    "character_model": "res://scripts/characters/character_model.gd",
    "tutorial": "res://scripts/tutorial/tutorial.gd",
}
GAMEPLAY_SCENES = {
    "train": "res://scenes/train/train.tscn",
    "gate": "res://scenes/station/fence_gate.tscn",
    "traffic_light": "res://scenes/station/traffic_light.tscn",
    "player": "res://scenes/player/player.tscn",
    "floating_text": "res://scenes/ui/floating_text.tscn",
    "hud": "res://scenes/ui/hud.tscn",
    "smoke": "res://scenes/train/train_smoke.tscn",
    "arrow": "res://scenes/tutorial/arrow.tscn",
}
SOUNDS = {
    "level_up": "res://assets/audio/sfx_level_up.wav",
    "music": "res://assets/audio/music_the_grey_room.mp3",
}
UPGRADE_SCENES = {
    "Wagon Unlock Indicator": ("WagonUnlock", "res://scenes/progression/wagon_unlock.tscn"),
    "Capacity Unlock Indicator": ("CapacityUpgrade", "res://scenes/progression/capacity_upgrade.tscn"),
    "Speed Unlock Indicator": ("SpeedUpgrade", "res://scenes/progression/speed_upgrade.tscn"),
}
PASSENGER_MODELS = ["character_female_%s" % c for c in "bcdef"] + ["character_male_%s" % c for c in "abcdef"]


def fbx_res(unity_path):
    """Unity FBX path -> Godot res:// path of the copied model."""
    base = os.path.splitext(os.path.basename(unity_path))[0]
    name = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", base).replace("-", "_").lower()
    for k, v in KITS.items():
        if k in unity_path:
            return "res://assets/models/%s/%s.fbx" % (v, name)
    return "res://assets/models/props/%s.fbx" % name


def quat_m(q):
    x, y, z, w = q
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


def local_m(n, with_scale=True):
    m = np.eye(4)
    m[:3, :3] = quat_m(n.rot) @ (np.diag(n.scale) if with_scale else np.eye(3))
    m[:3, 3] = n.pos
    return m


def to_godot(m):
    return MZ @ m @ MZ


def ortho(m):
    o = m.copy()
    for i in range(3):
        o[:3, i] = m[:3, i] / np.linalg.norm(m[:3, i])
    return o


def scale_of(m):
    return np.array([np.linalg.norm(m[:3, i]) for i in range(3)])


def fmt(v):
    v = round(float(v), 4)
    if abs(v) < 1e-4:
        return "0"
    return ("%.4f" % v).rstrip("0").rstrip(".")


def tf(m):
    if np.allclose(m, np.eye(4), atol=1e-6):
        return None
    vals = [m[i][j] for i in range(3) for j in range(3)] + [m[0][3], m[1][3], m[2][3]]
    return "Transform3D(%s)" % ", ".join(fmt(v) for v in vals)


def vec3(v):
    return "Vector3(%s)" % ", ".join(fmt(x) for x in v)


def node_name(name, fallback="Node"):
    name = name.replace("(", " ").replace(")", " ").replace("-", " ")
    parts = [p for p in re.split(r"[^A-Za-z0-9]+", name) if p]
    out = "".join(p[0].upper() + p[1:] for p in parts)
    return out or fallback


class Tscn:
    def __init__(self):
        self.ext = []
        self.sub = []
        self.nodes = []
        self.names = {}

    def ext_res(self, typ, path):
        for i, (t, p) in enumerate(self.ext):
            if p == path:
                return 'ExtResource("%d")' % (i + 1)
        self.ext.append((typ, path))
        return 'ExtResource("%d")' % len(self.ext)

    def sub_res(self, typ, props):
        key = (typ, tuple(props))
        for i, (t, p) in enumerate(self.sub):
            if (t, tuple(p)) == key:
                return 'SubResource("%s_%d")' % (t, i + 1)
        self.sub.append((typ, props))
        return 'SubResource("%s_%d")' % (typ, len(self.sub))

    def add(self, name, parent, typ=None, instance=None, props=None):
        """parent: None for root, '.' or a path. Returns the node path for children."""
        key = parent or ""
        base = name
        used = self.names.setdefault(key, set())
        i = 2
        while name in used:
            name = "%s%d" % (base, i)
            i += 1
        used.add(name)
        self.nodes.append((name, parent, typ, instance, props or []))
        if parent is None:
            return "."
        return name if parent == "." else parent + "/" + name

    def write(self, path):
        out = ["[gd_scene format=3]", ""]
        for i, (t, p) in enumerate(self.ext):
            out.append('[ext_resource type="%s" path="%s" id="%d"]' % (t, p, i + 1))
        if self.ext:
            out.append("")
        for i, (t, props) in enumerate(self.sub):
            out.append('[sub_resource type="%s" id="%s_%d"]' % (t, t, i + 1))
            out += ["%s = %s" % kv for kv in props]
            out.append("")
        for name, parent, typ, inst, props in self.nodes:
            head = '[node name="%s"' % name
            if typ:
                head += ' type="%s"' % typ
            if parent is not None:
                head += ' parent="%s"' % parent
            if inst:
                head += " instance=%s" % inst
            node_paths = [k for k, v in props if v is not None and str(v).startswith("NodePath(")]
            if node_paths:
                head += " node_paths=PackedStringArray(%s)" % ", ".join('"%s"' % k for k in node_paths)
            out.append(head + "]")
            out += ["%s = %s" % kv for kv in props if kv[1] is not None]
            out.append("")
        full = os.path.join(GODOT, path.replace("res://", ""))
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full, "w") as fh:
            fh.write("\n".join(out).rstrip() + "\n")
        print("wrote", path)


def material_of(n):
    for m in n.materials:
        if m and os.path.basename(m) in MATERIALS:
            return MATERIALS[os.path.basename(m)]
    return None


def skinned_model(n):
    for c in n.children:
        if any("SkinnedMeshRenderer" in o for o in c.other) and c.mesh:
            return c.mesh.split("#")[0]
    return None


def emit_visual(t, n, g, parent, name):
    """Emit the mesh/model of Unity node n with Godot transform g (relative to parent)."""
    if n.model:
        t.add(name, parent, instance=t.ext_res("PackedScene", fbx_res(n.model)), props=[("transform", tf(g @ F))])
        return True
    model = skinned_model(n)
    if model:
        t.add(name, parent, instance=t.ext_res("PackedScene", fbx_res(model)),
              props=[("transform", tf(g @ F)), ("script", t.ext_res("Script", SCRIPTS["character_model"]))])
        return True
    if not n.mesh:
        return False
    if n.mesh.startswith("builtin:"):
        kind = n.mesh.split(":")[1]
        s = scale_of(g)
        mat = material_of(n)
        mprops = [("material", t.ext_res("Material", mat))] if mat else []
        if kind == "Cube":
            mesh = t.sub_res("BoxMesh", mprops + [("size", vec3(s))])
        elif kind == "Cylinder":
            mesh = t.sub_res("CylinderMesh", mprops + [("top_radius", fmt(0.5 * s[0])),
                                                       ("bottom_radius", fmt(0.5 * s[0])),
                                                       ("height", fmt(2 * s[1]))])
        elif kind == "Quad":
            # Ground: a quad laid flat; its two in-plane axes are scale x and y.
            mesh = t.sub_res("PlaneMesh", mprops + [("size", "Vector2(%s, %s)" % (fmt(s[0]), fmt(s[1])))])
            flat = np.eye(4)
            flat[:3, 3] = g[:3, 3]
            t.add(name, parent, "MeshInstance3D", props=[("transform", tf(flat)), ("mesh", mesh)])
            return True
        else:
            raise ValueError(kind)
        t.add(name, parent, "MeshInstance3D", props=[("transform", tf(ortho(g))), ("mesh", mesh)])
        return True
    fbx, fid = n.mesh.split("#")
    split = SPLIT_MESHES.get((os.path.basename(fbx), fid))
    if split:
        mat = material_of(n)
        props = [("transform", tf(g @ F)), ("mesh", t.ext_res("ArrayMesh", split))]
        if mat:
            props.append(("material_override", t.ext_res("Material", mat)))
        t.add(name, parent, "MeshInstance3D", props=props)
        return True
    t.add(name, parent, instance=t.ext_res("PackedScene", fbx_res(fbx)), props=[("transform", tf(g @ F))])
    return fbx  # the whole FBX is instanced: its own sub-nodes must not be emitted again


def emit_shapes(t, n, m_unity, body_g, parent):
    """Collision shapes of node n (Unity world matrix m_unity) under a body with Godot transform body_g."""
    inv = np.linalg.inv(body_g)
    s = scale_of(m_unity)
    for c in n.colliders:
        if "Box" in c:
            b = c["Box"]
            size = np.array([b["size"]["x"], b["size"]["y"], b["size"]["z"]]) * s
            center = np.array([b["center"]["x"], b["center"]["y"], b["center"]["z"], 1.0])
            world = MZ @ (m_unity @ center)
            local = np.eye(4)
            rot = inv @ ortho(to_godot(m_unity))
            local[:3, :3] = rot[:3, :3]
            local[:3, 3] = (inv @ world)[:3]
            shape = t.sub_res("BoxShape3D", [("size", vec3(size))])
            t.add("CollisionShape3D", parent, "CollisionShape3D", props=[("transform", tf(local)), ("shape", shape)])
        elif "Mesh" in c and c["Mesh"] == "builtin:Quad":
            shape = t.sub_res("WorldBoundaryShape3D", [])
            t.add("CollisionShape3D", parent, "CollisionShape3D", props=[("shape", shape)])
        else:
            raise ValueError(c)


def bake(t, n, m_parent, parent, as_root=False, skip=lambda node: False):
    """Flatten Unity node n (and children) under Godot node `parent`. m_parent: Unity matrix of parent."""
    if skip(n):
        return
    m = m_parent @ local_m(n)
    g = to_godot(m)
    name = node_name(n.name)
    if name == "Model" or not name:
        name = "Model"
    if any("ParticleSystem" in o for o in n.other):
        at = np.eye(4)
        at[:3, 3] = g[:3, 3]
        t.add("Smoke", parent, instance=t.ext_res("PackedScene", GAMEPLAY_SCENES["smoke"]),
              props=[("transform", tf(at))])
        return
    if n.colliders:
        body_g = ortho(g)
        if n.mesh == "builtin:Quad":
            body_g[:3, :3] = np.eye(3)  # the ground quad lies flat; Godot's PlaneMesh already does
        if as_root:
            path = "."
            t.nodes[0] = (t.nodes[0][0], None, "StaticBody3D", None, [])
            assert np.allclose(body_g, np.eye(4)), "root body must sit at the origin"
        else:
            path = t.add(name, parent, "StaticBody3D", props=[("transform", tf(body_g))])
        rel = np.linalg.inv(body_g) @ g
        emitted = emit_visual(t, n, rel, path, "Mesh" if not n.model else "Model")
        emit_shapes(t, n, m, body_g, path)
    else:
        emitted = emit_visual(t, n, g, parent, name)
        if emitted and (n.model or skinned_model(n)):
            return
    for c in n.children:
        if isinstance(emitted, str) and c.mesh and c.mesh.startswith(emitted + "#"):
            continue
        bake(t, c, m, parent, skip=skip)


def prefab_scene(res, rel, r):
    roots, _ = r.load(rel)
    root = roots[0]
    t = Tscn()
    t.add(node_name(root.name), None, "Node3D")
    # The instance places the root (position/rotation); the prefab's own root scale is baked in.
    m_root = np.eye(4)
    m_root[:3, :3] = np.diag(root.scale)
    only_scale = us.Node(root.name)
    only_scale.__dict__.update({k: v for k, v in root.__dict__.items() if k not in ("pos", "rot", "scale")})
    only_scale.pos, only_scale.rot, only_scale.scale = [0, 0, 0], [0, 0, 0, 1], root.scale
    bake(t, only_scale, np.eye(4), ".", as_root=True)
    t.write(res)
    return root.scale


def structured(t, n, parent, prefab_scales, skip=()):
    """Keep Unity's hierarchy as Node3D containers; prefab roots become scene instances."""
    for c in n.children:
        if c.name in skip:
            continue
        g = to_godot(local_m(c))
        name = node_name(c.name)
        scene = PREFAB_SCENES.get(c.prefab)
        if scene:
            default = prefab_scales[c.prefab]
            ratio = np.array(c.scale) / np.array(default)
            inst = to_godot(local_m(c, with_scale=False))
            if not np.allclose(ratio, 1, atol=1e-3):
                inst[:3, :3] = inst[:3, :3] @ np.diag(ratio)
                print("  note: %s scaled %s relative to its prefab" % (c.name, ratio))
            t.add(name, parent, instance=t.ext_res("PackedScene", scene), props=[("transform", tf(inst))])
        elif c.mesh or c.model or c.colliders:
            bake(t, c, np.eye(4), parent)
        else:
            assert np.allclose(c.scale, 1), c.name
            path = t.add(name, parent, "Node3D", props=[("transform", tf(g))])
            structured(t, c, path, prefab_scales)


def number_of(node):
    m = re.search(r"\((\d+)\)", node.name)
    return int(m.group(1)) if m else 0


def by_number(nodes):
    return sorted(nodes, key=number_of)


def subtree_scene(r, prefab_rel, child_name, res, skip):
    """Bake one child of a prefab (relative to the prefab root) into its own scene."""
    roots, _ = r.load(prefab_rel)
    child = find(roots[0].children, child_name)
    t = Tscn()
    t.add(node_name(child_name) + "Model", None, "Node3D")
    bake(t, child, np.eye(4), ".", skip=skip)
    t.write(res)


def add_places(t, queue_node, parent):
    """Marker3D per Unity queue position, front first."""
    holder = find(queue_node.children, "Queue Positions")
    for pos in by_number(holder.children):
        g = to_godot(local_m(holder) @ local_m(pos))
        t.add("Place%d" % number_of(pos), parent, "Marker3D", props=[("transform", tf(g))])


def add_gameplay(t, game, station_env):
    """Gameplay nodes of one station, placed from the right station of Game.unity."""
    controllers = find(find(game, "-- RIGHT STATIONS --").children, "-- CONTROLLERS --")
    refs = find(station_env.children, "References Positions")
    for unity_name, name in (("Start Position", "TrainStart"), ("Station Position", "TrainStop"),
                             ("End Position", "TrainEnd")):
        g = to_godot(local_m(refs) @ local_m(find(refs.children, unity_name)))
        t.add(name, ".", "Marker3D", props=[("transform", tf(g))])
    start = to_godot(local_m(refs) @ local_m(find(refs.children, "Start Position")))
    t.add("Train", ".", instance=t.ext_res("PackedScene", GAMEPLAY_SCENES["train"]),
          props=[("transform", tf(start))])

    group = find(controllers.children, "Group Boarding Queue")
    path = t.add("Boarding", ".", "Node3D", props=[("transform", tf(to_godot(local_m(group)))),
                                                   ("script", t.ext_res("Script", SCRIPTS["boarding"]))])
    for queue in by_number(group.children):
        qpath = t.add("WagonQueue%d" % number_of(queue), path, "Node3D",
                      props=[("transform", tf(to_godot(local_m(queue)))),
                             ("script", t.ext_res("Script", SCRIPTS["wagon_queue"]))])
        add_places(t, queue, qpath)

    group = find(controllers.children, "Group Revolving Doors")
    path = t.add("Gates", ".", "Node3D", props=[("transform", tf(to_godot(local_m(group))))])
    for gate in by_number(group.children):
        assert np.allclose(gate.scale, 1)
        t.add("FenceGate%d" % number_of(gate), path, instance=t.ext_res("PackedScene", GAMEPLAY_SCENES["gate"]),
              props=[("transform", tf(to_godot(local_m(gate))))])

    light = find(controllers.children, "Traffic Light")
    t.add("TrafficLight", ".", instance=t.ext_res("PackedScene", GAMEPLAY_SCENES["traffic_light"]),
          props=[("transform", tf(to_godot(local_m(light))))])

    progressions = find(find(game, "-- RIGHT STATIONS --").children, "-- PROGRESSIONS --")
    revenue = find(progressions.children, "Passenger Revenue Controller")
    path = t.add("Revenue", ".", "Node3D", props=[("transform", tf(to_godot(local_m(revenue)))),
                                                  ("script", t.ext_res("Script", SCRIPTS["revenue"]))])
    text = find(revenue.children, "Camera Facing Text ")
    t.add("FloatingText", path, instance=t.ext_res("PackedScene", GAMEPLAY_SCENES["floating_text"]),
          props=[("transform", tf(ortho(to_godot(local_m(text)))))])
    t.add("CoinSound", path, "AudioStreamPlayer", props=[("stream", t.ext_res("AudioStream", SOUNDS["level_up"])),
                                                         ("volume_db", "-6.02")])

    spawner = find(controllers.children, "Character Spawn Controller")
    models = ", ".join(t.ext_res("PackedScene", "res://assets/models/kenney_mini_characters/%s.fbx" % m)
                       for m in PASSENGER_MODELS)
    t.add("PassengerSpawner", ".", "Node3D", props=[("transform", tf(to_godot(local_m(spawner)))),
                                                    ("script", t.ext_res("Script", SCRIPTS["spawner"])),
                                                    ("model_scenes", "Array[PackedScene]([%s])" % models)])


def find(nodes, name):
    for n in nodes:
        if n.name == name:
            return n
    raise KeyError(name)


def main():
    r = us.Resolver(UNITY)
    os.chdir(UNITY)
    scales = {rel: prefab_scene(res, rel, r) for rel, res in PREFAB_SCENES.items()}

    game, _ = r.load("Assets/Level/Scenes/Game.unity")
    right = find(find(game, "-- RIGHT STATIONS --").children, "-- ENVIORNMENT --")
    left = find(find(game, "-- LEFT STATIONS --").children, "-- ENVIORNMENT --")

    subtree_scene(r, "Assets/Level/Prefabs/Traffic Light.prefab", "Traffic Light",
                  "res://scenes/station/traffic_light_model.tscn", skip=lambda node: node.name.endswith(" Off"))

    station = Tscn()
    station.add("Station", None, "Node3D")
    station.nodes[0] = ("Station", None, "Node3D", None,
                        [("script", station.ext_res("Script", SCRIPTS["station"])),
                         ("settings", station.ext_res("Resource", "res://resources/progression_settings.tres"))])
    path = station.add("Environment", ".", "Node3D")
    structured(station, right, path, scales, skip=("References Positions",))
    add_gameplay(station, game, right)
    station.write("res://scenes/station/station.tscn")
    compare_stations(right, left)

    env_scene, _ = r.load("Assets/Level/Scenes/Environment.unity")
    level = Tscn()
    level.add("Game", None, "Node3D")
    env = find(env_scene, "-- ENVIRONMENT --")
    path = level.add("Environment", ".", "Node3D")
    structured(level, env, path, scales)
    level.add("RightStation", ".", instance=level.ext_res("PackedScene", "res://scenes/station/station.tscn"))
    rot180 = np.diag([-1.0, 1.0, -1.0, 1.0])
    # Left station values that differ from the right one (save keys, gate prices; its first
    # gate starting unlocked is in save_defaults.json).
    level.add("LeftStation", ".", instance=level.ext_res("PackedScene", "res://scenes/station/station.tscn"),
              props=[("transform", tf(rot180)), ("save_prefix", '"left"'),
                     ("gate_prices", "Array[int]([50, 100, 200, 400])")])
    for station_name, unity_name, station_m in (("RightStation", "-- RIGHT STATIONS --", np.eye(4)),
                                                ("LeftStation", "-- LEFT STATIONS --", rot180)):
        add_upgrades(level, game, station_name, unity_name, station_m)
    add_tutorial(level, game)
    level.add("HUD", ".", instance=level.ext_res("PackedScene", GAMEPLAY_SCENES["hud"]))
    # Unity: the Game scene's looping music source at volume 0.3.
    level.add("Music", ".", "AudioStreamPlayer", props=[("stream", level.ext_res("AudioStream", SOUNDS["music"])),
                                                        ("volume_db", "-10.46"), ("autoplay", "true")])
    player = find(game, "Player")
    level.add("Player", ".", instance=level.ext_res("PackedScene", GAMEPLAY_SCENES["player"]),
              props=[("transform", tf(to_godot(local_m(player))))])

    light = find(env_scene, "Directional Light")
    level.add("DirectionalLight3D", ".", "DirectionalLight3D",
              props=[("transform", tf(to_godot(local_m(light)))), ("light_energy", "1.1"),
                     ("light_color", "Color(1, 0.94, 0.85, 1)"),
                     ("shadow_enabled", "true"), ("directional_shadow_max_distance", "40.0")])
    cam = find(game, "Main Camera")
    level.add("Camera3D", ".", "Camera3D", props=[("transform", tf(to_godot(local_m(cam)))), ("fov", "60.0"),
                                                  ("near", "0.05"), ("far", "1000.0"),
                                                  ("script", level.ext_res("Script", SCRIPTS["camera"])),
                                                  ("target", 'NodePath("../Player")')])
    sky_mat = level.sub_res("ProceduralSkyMaterial", [])
    sky = level.sub_res("Sky", [("sky_material", sky_mat)])
    envr = level.sub_res("Environment", [
        ("background_mode", "2"), ("sky", sky),
        ("ambient_light_source", "2"), ("ambient_light_color", "Color(0.6603774, 0.45193467, 0.27100393, 1)"),
        ("ambient_light_energy", "0.3"),
        ("fog_enabled", "true"), ("fog_mode", "1"),
        # Warmer and softer than Unity's (light 2, grey fog), which looked blown out in Godot.
        ("fog_light_color", "Color(0.96, 0.87, 0.76, 1)"),
        ("fog_density", "1.0"), ("fog_depth_begin", "0.0"), ("fog_depth_end", "300.0"),
    ])
    level.add("WorldEnvironment", ".", "WorldEnvironment", props=[("environment", envr)])
    level.write("res://scenes/levels/lvl_game.tscn")


def add_upgrades(t, game, station_name, unity_name, station_m):
    """Upgrade plates of one station; they are not mirrored between stations, so each gets its own."""
    progressions = find(find(game, unity_name).children, "-- PROGRESSIONS --")
    path = t.add("Upgrades", station_name, "Node3D")
    inv = np.linalg.inv(station_m)
    for unity_plate, (name, scene) in UPGRADE_SCENES.items():
        plate = find(progressions.children, unity_plate)
        world = local_m(find(progressions.children, unity_plate))
        t.add(name, path, instance=t.ext_res("PackedScene", scene),
              props=[("transform", tf(inv @ to_godot(world)))])


def add_tutorial(t, game):
    """The tutorial only exists on the right station in Unity."""
    controllers = find(find(game, "-- RIGHT STATIONS --").children, "-- CONTROLLERS --")
    tutorial = find(controllers.children, "Tutorial Controller")
    path = t.add("Tutorial", "RightStation", "Node3D", props=[("script", t.ext_res("Script", SCRIPTS["tutorial"]))])
    for unity_name, name in (("Fence Transform", "FenceTarget"), ("Traffic Light Transform", "TrafficLightTarget")):
        g = to_godot(local_m(find(tutorial.children, unity_name)))
        t.add(name, path, "Marker3D", props=[("transform", tf(g))])
    arrow = find(tutorial.children, "Arrow")
    t.add("Arrow", path, instance=t.ext_res("PackedScene", GAMEPLAY_SCENES["arrow"]),
          props=[("transform", tf(to_godot(local_m(arrow))))])


def compare_stations(right, left):
    """Left station must be the right one turned 180 degrees, or one shared scene is wrong."""
    rot = np.diag([-1.0, 1.0, -1.0, 1.0])

    def walk(n, m, out, path=""):
        m = m @ local_m(n)
        out[path + "/" + n.name] = m
        for c in n.children:
            walk(c, m, out, path + "/" + n.name)

    a, b = {}, {}
    for c in right.children:
        walk(c, np.eye(4), a)
    for c in left.children:
        walk(c, np.eye(4), b)
    bad = [k for k in a if k in b and not np.allclose(rot @ a[k], b[k], atol=5e-3)]
    missing = set(a) ^ set(b)
    print("station mirror check: %d differ, %d missing" % (len(bad), len(missing)))
    for k in bad[:10]:
        print("  differs:", k)
    for k in list(missing)[:10]:
        print("  missing:", k)


if __name__ == "__main__":
    main()
