# ASSET_PLACEMENT.md

This guide tells you exactly where every file belongs in this project.
It is written for beginners: when you add a file, read this first.

## Project decisions (agreed)

- Engine: Godot 4
- Gameplay: 3D third-person exploration
- Setting: a Victorian church exterior, an NHM-style museum interior,
  and visual city scenery around them
- Future: educational object interactions inside the museum
- Current phase: organization only. No gameplay, scenes, scripts, UI,
  lighting, or placeholder assets yet.

## Folder tree

res:// means the project root on disk.

```
res://
|-- ASSET_PLACEMENT.md        (this guide)
|-- assets/
|   |-- environment/
|   |   |-- buildings/        (whole buildings: church exterior, museum interior)
|   |   |-- city/             (city scenery: streets, plazas, districts)
|   |   |-- props/            (small objects: benches, lampposts, signs)
|   |   |-- imported/         (raw assets from outside, unmodified)
|   |   `-- generated/        (assets created by Summer Engine tools)
|   |-- characters/           (character models)
|   |-- animations/           (character animations)
|   |-- textures/             (separate texture images)
|   `-- materials/            (Godot material resources)
|-- scenes/                   (Godot .tscn scenes)
|-- scripts/                  (Godot .gd scripts)
|-- ui/                       (user interface scenes and scripts)
|-- audio/                    (sound effects, music, ambience)
`-- data/
    `-- educational/          (future educational object data)
```

## Where each file goes

### Church and museum models (GLB)

- Victorian church exterior: res://assets/environment/buildings/church_exterior.glb
- Museum interior: res://assets/environment/buildings/museum_interior.glb
- Any other whole building: res://assets/environment/buildings/

### City scenery models (GLB)

- Streets, plazas, sidewalks, and background districts:
  res://assets/environment/city/

### Prop models (GLB)

- Benches, lampposts, signs, fences, trees, and similar objects:
  res://assets/environment/props/

### Character models (GLB)

- Player character and non-player characters:
  res://assets/characters/

### Animations

- Character animation packs (.glb/.gltf files that contain animations):
  res://assets/animations/

### Separate textures

- Standalone texture images (PNG/JPG/EXR) that are not packed inside a
  model: res://assets/textures/
- Name each texture to match its model, for example
  church_exterior_albedo.png.
- Textures already packed inside a GLB stay inside that GLB; do not
  extract them.

### Materials

- Godot material resources (.tres) that define how a surface looks:
  res://assets/materials/

### Scenes

- Every .tscn scene, including the future main scene:
  res://scenes/

### Scripts

- Every .gd GDScript file, including the future player controller and
  camera scripts: res://scripts/

### UI

- Every UI scene, UI script, and UI theme:
  res://ui/

### Audio

- Sound effects, music, and ambient audio:
  res://audio/

### Imported environment assets

- Raw environment assets received from outside the project, exactly as
  downloaded, unmodified: res://assets/environment/imported/
- Use this folder as a staging area. When an imported model is ready to
  be used, copy it to its final home in buildings/, city/, or props/.

### Generated environment assets

- Environment assets created or exported by Summer Engine tools (for
  example AI-generated models or tool exports):
  res://assets/environment/generated/
- Keep imported and generated assets separate so you always know where
  each asset came from.

### Educational data (future)

- Educational object information for museum interactions (JSON, text,
  or .tres data files): res://data/educational/

## Current phase

Organization only. The folders above exist now, but the game does not
exist yet. Do not add scenes, scripts, UI, lighting, or placeholder
assets yet. The next phase builds the main scene first.
