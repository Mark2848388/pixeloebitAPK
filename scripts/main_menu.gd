extends Control

@onready var coins_label: Label = $TopBar/Coins
@onready var hero_label: Label = $TopBar/Hero

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	coins_label.text = "C %d   G %d   S %d   ★ %d" % [GameState.coins, GameState.gems, GameState.scrap, GameState.high_score]
	var h: Dictionary = GameState.HEROES.get(GameState.active_hero, {})
	hero_label.text = str(h.get("name", "РЕКС"))

func _start(mode: String, world: int = 0, goal: int = 0) -> void:
	var packed: PackedScene = load("res://scenes/battle.tscn")
	var scn: Node = packed.instantiate()
	scn.setup(mode, world, goal)
	get_tree().root.add_child(scn)
	queue_free()

func _on_classic() -> void:
	_start("classic")

func _on_endless() -> void:
	_start("endless")

func _on_arena() -> void:
	_start("arena")

func _on_campaign() -> void:
	var next := GameState.campaign_world + 1
	if next > 10:
		next = 10
	_start("campaign", next, 3 + next)

func _on_hero_next() -> void:
	var ids: Array = GameState.owned_heroes
	if ids.is_empty():
		return
	var i := ids.find(GameState.active_hero)
	i = (i + 1) % ids.size()
	GameState.active_hero = ids[i]
	GameState.save_game()
	_refresh()
