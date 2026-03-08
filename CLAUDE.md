# CLAUDE.md — AI Assistant Guide for TheVillage

## Project Overview

**TheVillage** is a peaceful, cozy village simulation game built with **Godot 4 (GDScript)**.

- **License:** GNU General Public License v3
- **Engine:** Godot 4.3 (GL Compatibility renderer)
- **Language:** GDScript
- **Repository:** BronzeVille/TheVillage

---

## Repository Structure

```
TheVillage/
├── project.godot            ← Godot project config (edit via editor UI)
├── CLAUDE.md                ← This file
├── LICENSE                  ← GNU GPL v3
├── README.md                ← User-facing project description
├── .gitignore               ← Ignores .godot/, *.import, export_presets.cfg
│
├── scenes/
│   ├── world/
│   │   └── World.tscn       ← Main scene (entry point)
│   ├── characters/
│   │   ├── Player.tscn      ← Player character
│   │   └── NPC.tscn         ← Base NPC (extend for specific villagers)
│   └── ui/
│       └── HUD.tscn         ← On-screen UI (dialogue box, etc.)
│
├── scripts/
│   ├── World.gd             ← World scene controller
│   ├── Player.gd            ← Player movement and interaction
│   ├── NPC.gd               ← NPC base logic and dialogue
│   └── HUD.gd               ← HUD / dialogue box controller
│
└── assets/
    ├── sprites/             ← Character and object sprites
    ├── tilemaps/            ← Tileset images and TileMap data
    ├── audio/               ← Music and sound effects
    └── fonts/               ← Custom fonts
```

---

## Development Setup

1. Install **Godot 4.3** (standard, not .NET) from [godotengine.org](https://godotengine.org/download)
2. Open Godot → Import → select this repo's folder → open `project.godot`
3. The main scene is `scenes/world/World.tscn` — press F5 to run

No additional build tools or package managers required.

---

## GDScript Conventions

- **Types:** Always use static types (`var speed: float = 100.0`, `func move() -> void`)
- **Constants:** `SCREAMING_SNAKE_CASE` (`const MAX_SPEED: float = 200.0`)
- **Variables:** `snake_case`
- **Signals:** `snake_case` verb phrases (`player_interacted`, `dialogue_finished`)
- **Node references:** Use `@onready` and `$NodePath` — avoid `get_node()` where possible
- **Comments:** Use `##` for doc comments on exported vars and public functions
- **Exports:** Place `@export` vars at the top of the class, before `@onready`

### Script structure order

```gdscript
extends BaseClass

## Class doc comment

# Signals
signal some_event

# Constants
const SPEED: float = 100.0

# Exported variables
@export var npc_name: String = "Villager"

# Onready variables
@onready var sprite: Sprite2D = $Sprite2D

# Private variables
var _state: String = "idle"

# Built-in callbacks (_ready, _process, _input, etc.)
# Public methods
# Private methods
```

---

## Scene Conventions

- One `.tscn` file per logical entity (Player, NPC, HUD, etc.)
- Scene files live in `scenes/<category>/`
- Scripts live in `scripts/` (not embedded in scenes)
- NPC variants: create new scenes that inherit from `NPC.tscn` (`Scene > New Inherited Scene`)
- UI scenes live in `scenes/ui/` and are added as `CanvasLayer` children of the world

---

## Git Workflow

### Branching

- Default branch: `master`
- Feature branches: `<feature-name>` or `<author>/<feature-name>`
- Claude-generated branches: `claude/<task>-<session-id>`

### Commit style

- Imperative, present tense: `Add player movement`, `Fix NPC dialogue loop`
- Keep commits focused and atomic
- Do not commit `.godot/`, `*.import`, or `export_presets.cfg` (covered by `.gitignore`)

### Push

```bash
git push -u origin <branch-name>
```

---

## For AI Assistants

1. **Read this file first** before making changes.
2. **Update this file** when adding new scenes, systems, or conventions.
3. **Do not embed scripts in scenes** — keep all logic in `scripts/`.
4. **Prefer editing existing scripts** over creating new ones for small additions.
5. **Respect GPL v3** — all contributions must be compatible with the license.
6. **Never commit** `.godot/`, `*.import`, or binary assets without explicit instruction.
7. Scene UIDs (e.g. `uid://world_main`) are placeholders — Godot will assign real UIDs on first open; do not worry about them being non-canonical.

---

## License

GNU General Public License v3. See [LICENSE](./LICENSE). All contributions must be GPL v3 compatible.
