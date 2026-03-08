extends Node2D

## World scene controller.
## Defines the tribe, places named locations, spawns villagers,
## and wires HUD signals.

const VILLAGER_SCENE: PackedScene = preload("res://scenes/characters/Villager.tscn")

# ---------------------------------------------------------------------------
# Tribe definition
# Tweak names, roles, personalities freely — this is the only place needed.
# ---------------------------------------------------------------------------
const TRIBE: Array[Dictionary] = [
	{
		"name":        "Asha",
		"role":        "Elder",
		"personality": "Wise, measured, protective of tradition, slow to anger",
		"skills":      "Leadership, herbal lore, ritual knowledge, dispute mediation",
		"color":       Color(0.85, 0.75, 0.3),
	},
	{
		"name":        "Keva",
		"role":        "Farmer",
		"personality": "Diligent, pragmatic, quietly stubborn, proud of the harvest",
		"skills":      "Grain cultivation, irrigation, food preservation",
		"color":       Color(0.4, 0.7, 0.3),
	},
	{
		"name":        "Doran",
		"role":        "Hunter",
		"personality": "Bold, restless, proud of his catches, competitive",
		"skills":      "Tracking, spear-throwing, forest navigation, reading weather",
		"color":       Color(0.7, 0.35, 0.2),
	},
	{
		"name":        "Mira",
		"role":        "Potter",
		"personality": "Patient, creative, meticulous, values beauty in objects",
		"skills":      "Clay shaping, kiln management, trade goods, storage design",
		"color":       Color(0.6, 0.4, 0.6),
	},
	{
		"name":        "Bren",
		"role":        "Farmer",
		"personality": "Steady, kind-hearted, worries about winter, cautious planner",
		"skills":      "Farming, tool repair, basic carpentry, animal husbandry",
		"color":       Color(0.35, 0.6, 0.35),
	},
	{
		"name":        "Sela",
		"role":        "Healer",
		"personality": "Empathetic, observant, speaks little, notices suffering",
		"skills":      "Herb medicine, wound care, midwifery, fever treatment",
		"color":       Color(0.5, 0.75, 0.75),
	},
	{
		"name":        "Tomas",
		"role":        "Hunter",
		"personality": "Eager, competitive, wants to prove himself, impulsive",
		"skills":      "Archery, scouting, fast running, trap-setting",
		"color":       Color(0.8, 0.5, 0.2),
	},
	{
		"name":        "Lira",
		"role":        "Weaver",
		"personality": "Sociable, diplomatic, sharp memory for social bonds",
		"skills":      "Weaving, leatherwork, social negotiation, trade relations",
		"color":       Color(0.7, 0.3, 0.5),
	},
	{
		"name":        "Oryn",
		"role":        "Gatherer",
		"personality": "Curious, energetic, loves to explore, sometimes wanders too far",
		"skills":      "Foraging, plant identification, river fishing, endurance",
		"color":       Color(0.3, 0.55, 0.75),
	},
	{
		"name":        "Vell",
		"role":        "Craftsman",
		"personality": "Inventive, gruff, proud of his work, dislikes wasted effort",
		"skills":      "Tool making, woodwork, clay firing, problem solving",
		"color":       Color(0.55, 0.45, 0.35),
	},
	{
		"name":        "Nira",
		"role":        "Elder's Aide",
		"personality": "Serious beyond her years, observant, loyal to Asha",
		"skills":      "Memory keeping, ritual assistance, herbal preparation",
		"color":       Color(0.75, 0.65, 0.85),
	},
	{
		"name":        "Cai",
		"role":        "Child",
		"personality": "Playful, eager to help, easily distracted, curious about everything",
		"skills":      "Basic foraging, running errands, learning from elders",
		"color":       Color(0.9, 0.8, 0.4),
	},
]

# Spawn positions scattered around the village hearth
const SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(205, 305), Vector2(225, 315), Vector2(245, 300),
	Vector2(200, 335), Vector2(260, 320), Vector2(215, 355),
	Vector2(235, 340), Vector2(255, 345), Vector2(270, 310),
	Vector2(190, 320), Vector2(248, 360), Vector2(218, 280),
]

@onready var _villagers_node: Node2D = $Villagers
@onready var _hud: Control           = $UI/HUD
@onready var _sim_clock: Node        = $SimClock


func _ready() -> void:
	_setup_locations()
	_spawn_villagers()
	_sim_clock.hour_passed.connect(_on_hour_passed)


func _setup_locations() -> void:
	WorldState.locations = {
		"fields":    Vector2(560, 500),
		"river":     Vector2(75,  285),
		"riverbank": Vector2(95,  315),
		"forest":    Vector2(630, 185),
		"workshop":  Vector2(330, 475),
		"hearth":    Vector2(225, 345),
		"shelter":   Vector2(200, 400),
		"shrine":    Vector2(410, 195),
		"anywhere":  Vector2(225, 345),
	}


func _spawn_villagers() -> void:
	for i in TRIBE.size():
		var data: Dictionary          = TRIBE[i]
		var villager: CharacterBody2D = VILLAGER_SCENE.instantiate()
		villager.villager_name = data["name"]
		villager.role          = data["role"]
		villager.personality   = data["personality"]
		villager.skills        = data["skills"]
		villager.body_color    = data["color"]
		villager.position      = SPAWN_POSITIONS[i]
		_villagers_node.add_child(villager)
		villager.action_started.connect(_on_villager_speech)
		villager.thought_updated.connect(_on_villager_thought)


func _on_villager_speech(villager: Node, _action: String, speech: String) -> void:
	_hud.show_speech(villager.villager_name, speech)


func _on_villager_thought(villager: Node, thought: String) -> void:
	_hud.show_thought(villager.villager_name, thought)


func _on_hour_passed(_hour: float) -> void:
	_hud.refresh_resources()
