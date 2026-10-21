# Train Rush

Godot 4.7 (GL Compatibility) port of the Unity game in `unity/TrainRush/` (reference only, its
own git repo, ignored here). 3D, web build published on GitHub Pages (no CrazyGames SDK).

- Game design: `docs/gdd.md`. Plan: `docs/roadmap.md`. Keep all project docs in `docs/`.
- Vibe coded: no design note is needed before code, but stay inside the current roadmap phase;
  new ideas go to the backlog.
- The port must play like the Unity version; check behavior and numbers in its scripts and
  scenes before guessing.
- `tools/unity_port/gen_godot.py` regenerates the environment scenes from the Unity scenes and
  overwrites them.
- Must run in a web export: no threads, no native-only APIs.
