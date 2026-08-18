---
name: victorian-museum-exploration
overview: >-
  Organize the Godot project for a Victorian church, NHM-style museum interior,
  city scenery, imported GLB assets, and a later third-person educational
  exploration slice.
createdAt: '2026-08-17T17:45:10.020Z'
todos:
  - id: project-structure
    content: >-
      Create the organized folder structure and asset placement guide without
      adding gameplay or placeholder assets.
    status: completed
  - id: asset-intake
    content: >-
      Import and catalog the user's existing GLB, texture, and supporting assets
      after they are placed in the documented folders.
    status: pending
  - id: playable-exploration
    content: >-
      Build the first playable third-person exploration slice around the
      approved church and museum assets.
    status: pending
  - id: education-interactions
    content: Add object interactions that show historical and educational information.
    status: pending
template: third-person-adventure-slice
---
Scope for this phase: organization only. The user explicitly asked not to create the game, player controller, camera, UI, lighting system, or gameplay yet.

Design decisions:
- Target: Godot 4, 3D, third-person exploration.
- Future spine: the third-person adventure slice pattern, because it matches camera-relative exploration and later collectible/objective interaction, but it is not installed or implemented in this phase.
- Asset-first workflow: existing GLB files are placed into clearly named folders before any scene construction.
- Keep imported/generated assets separate from hand-authored scenes and scripts so the project stays understandable for a beginner.

Verification for this phase:
- The requested folders exist through their placement-guide files.
- Each GLB category has an explicit destination.
- No gameplay scene, controller, camera, UI, lighting system, or placeholder asset is added.
- Stop after the structure is created and wait for the user to place assets and approve the next stage.
