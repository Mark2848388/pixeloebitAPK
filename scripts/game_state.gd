extends Node
## Autoload singleton for progress

var coins: int = 200
var gems: int = 30
var scrap: int = 0
var high_score: int = 0
var campaign_world: int = 0
var active_hero: String = "rex"
var owned_heroes: Array = ["rex"]
var player_name: String = "Pilot"

const HEROES := {
	"rex": {"name": "РЕКС", "color": Color(0.29, 0.48, 1.0), "rate": 1.0, "dmg": 1.0, "speed": 1.0, "lives": 0},
	"nova": {"name": "НОВА", "color": Color(1.0, 0.38, 0.75), "rate": 0.65, "dmg": 0.85, "speed": 1.0, "lives": 0},
	"bolt": {"name": "БОЛТ", "color": Color(1.0, 0.69, 0.13), "rate": 1.0, "dmg": 1.0, "speed": 1.4, "lives": 0},
	"aegis": {"name": "ЭГИДА", "color": Color(0.19, 0.75, 0.44), "rate": 1.0, "dmg": 0.9, "speed": 1.0, "lives": 1},
	"shadow": {"name": "ТЕНЬ", "color": Color(0.54, 0.25, 0.88), "rate": 1.15, "dmg": 1.55, "speed": 1.0, "lives": 0},
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("p", "coins", coins)
	cfg.set_value("p", "gems", gems)
	cfg.set_value("p", "scrap", scrap)
	cfg.set_value("p", "hi", high_score)
	cfg.set_value("p", "cw", campaign_world)
	cfg.set_value("p", "hero", active_hero)
	cfg.set_value("p", "heroes", owned_heroes)
	cfg.set_value("p", "name", player_name)
	cfg.save("user://progress.cfg")

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://progress.cfg") != OK:
		return
	coins = int(cfg.get_value("p", "coins", 200))
	gems = int(cfg.get_value("p", "gems", 30))
	scrap = int(cfg.get_value("p", "scrap", 0))
	high_score = int(cfg.get_value("p", "hi", 0))
	campaign_world = int(cfg.get_value("p", "cw", 0))
	active_hero = str(cfg.get_value("p", "hero", "rex"))
	owned_heroes = cfg.get_value("p", "heroes", ["rex"])
	player_name = str(cfg.get_value("p", "name", "Pilot"))

func add_score(score: int) -> void:
	if score > high_score:
		high_score = score
	coins += clampi(score / 10, 0, 500)
	scrap += clampi(score / 40, 0, 25)
	save_game()

func clear_world(id: int) -> void:
	if id > campaign_world:
		campaign_world = id
		coins += 80 + id * 25
		gems += 2
		if id >= 2 and not owned_heroes.has("nova"):
			owned_heroes.append("nova")
		if id >= 3 and not owned_heroes.has("bolt"):
			owned_heroes.append("bolt")
		if id >= 5 and not owned_heroes.has("aegis"):
			owned_heroes.append("aegis")
		if id >= 7 and not owned_heroes.has("shadow"):
			owned_heroes.append("shadow")
		save_game()
