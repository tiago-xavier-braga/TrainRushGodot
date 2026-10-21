# Folder Structure

This is a single Godot 4.7 game. Top-level folders by file type, with a subfolder per feature
inside each.

```
res://
├── addons/                    # shared plugins (leaf_tween, save_kit)
├── assets/                    # media, grouped by kind
│   ├── fonts/
│   ├── materials/             # mat_*.tres
│   ├── models/                # one folder per Kenney kit + props/ (own models)
│   └── textures/              # txt_*.png, kenney/ and props/
├── scenes/                    # .tscn, one subfolder per feature
│   ├── environment/           # static station pieces (fence, gates, rails...)
│   ├── levels/                # lvl_game.tscn (main scene)
│   └── station/               # one platform; the level instances it twice
├── scripts/                   # .gd, one subfolder per feature (same names as scenes/)
├── resources/                 # .tres data and save_defaults.json (Save Kit)
├── docs/                      # gdd.md, roadmap.md, feedback.md
├── tools/unity_port/          # Python scripts that convert the Unity scenes (.gdignore)
├── unity/                     # optional clone of the Unity project (git-ignored)
├── icon.svg
└── project.godot
```

Rules:

- Scenes go in `scenes/<feature>/`, scripts in `scripts/<feature>/`. The feature folder name
  matches in both.
- Level scenes live in `scenes/levels/` and are prefixed `lvl_`.
- Materials are prefixed `mat_`, textures `txt_`, and live under `assets/`.
- Kenney models keep their kit folder and file names (snake_case) and the kit's `license.txt`.
- Custom resources (`.tres` data defined by a `Resource` script) go in `resources/`; the script
  that defines them stays in `scripts/`.
- Project documentation lives in `docs/`.
- Don't create empty folders "for the future". A folder only exists once it has content.
- Build output (web export) is never committed; it goes in `build/`, which is git-ignored.
- Tweens go through the `LeafTween` autoload (`addons/leaf_tween`), not Godot's `Tween`.
