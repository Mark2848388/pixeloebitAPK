extends Node2D
## Core shooter arena

const W := 360.0
const H := 640.0

var mode: String = "classic" # classic | endless | campaign | arena
var world_id: int = 0
var waves_goal: int = 0

var score: int = 0
var lives: int = 3
var wave: int = 0
var game_over: bool = false
var victory: bool = false

var player_x: float = 180.0
var player_y: float = 560.0
var target_x: float = 180.0
var fire_cd: float = 0.0
var dash_cd: float = 0.0
var ult_cd: float = 0.0
var dash_t: float = 0.0
var shield_t: float = 0.0
var spawn_t: float = 0.5
var banner: String = ""
var banner_t: float = 0.0
var shake: float = 0.0
var tick: int = 0

var hero_id: String = "rex"
var rate_mul: float = 1.0
var dmg_mul: float = 1.0
var speed_mul: float = 1.0

var entities: Array = [] # dicts
var stars: Array = []
var rng := RandomNumberGenerator.new()

@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	rng.randomize()
	hero_id = GameState.active_hero
	var h: Dictionary = GameState.HEROES.get(hero_id, GameState.HEROES["rex"])
	rate_mul = float(h.get("rate", 1.0))
	dmg_mul = float(h.get("dmg", 1.0))
	speed_mul = float(h.get("speed", 1.0))
	lives = 3 + int(h.get("lives", 0))
	for i in 48:
		stars.append(Vector2(rng.randf() * W, rng.randf() * H))
	if mode == "arena":
		_spawn_rival()
		_set_banner("АРЕНА")
	else:
		_next_wave(true)
	queue_redraw()

func setup(p_mode: String, p_world: int = 0, p_goal: int = 0) -> void:
	mode = p_mode
	world_id = p_world
	waves_goal = p_goal

func _process(dt: float) -> void:
	if game_over:
		queue_redraw()
		return
	dt = clampf(dt, 0.0, 0.05)
	tick += 1
	shake = maxf(0.0, shake - dt * 8.0)
	if banner_t > 0.0:
		banner_t -= dt
	dash_cd = maxf(0.0, dash_cd - dt)
	ult_cd = maxf(0.0, ult_cd - dt)
	dash_t = maxf(0.0, dash_t - dt)
	shield_t = maxf(0.0, shield_t - dt)

	# move player
	var dx := target_x - player_x
	var mul := speed_mul * (2.2 if dash_t > 0.0 else 1.0)
	player_x += clampf(dx * 14.0 * mul * dt, -480.0 * mul * dt, 480.0 * mul * dt)
	player_x = clampf(player_x, 20.0, W - 20.0)

	# fire
	fire_cd -= dt
	if fire_cd <= 0.0 and dash_t <= 0.0:
		fire_cd = clampf(0.16 * rate_mul, 0.07, 0.4)
		_player_shot()

	# waves
	if mode != "arena":
		var has_enemy := false
		for e in entities:
			if e.get("dead", false):
				continue
			var k: String = e["kind"]
			if k == "enemy" or k == "enemy2" or k == "boss":
				has_enemy = true
				break
		if not has_enemy:
			spawn_t -= dt
			if spawn_t <= 0.0:
				spawn_t = 0.4 if mode == "endless" else 0.75
				_next_wave(false)
		if mode == "endless" and tick % 90 == 0:
			entities.append({
				"kind": "enemy", "x": 40 + rng.randf() * (W - 80), "y": -20.0,
				"vx": (rng.randf() - 0.5) * 50.0, "vy": 90.0 + wave * 8.0,
				"hp": 1.0, "max_hp": 1.0, "r": 12.0, "dead": false, "age": 0.0, "phase": 1
			})
	else:
		_update_arena(dt)

	# update entities
	for e in entities:
		if e.get("dead", false):
			continue
		e["age"] = float(e.get("age", 0.0)) + dt
		e["x"] = float(e["x"]) + float(e.get("vx", 0.0)) * dt
		e["y"] = float(e["y"]) + float(e.get("vy", 0.0)) * dt
		var k: String = e["kind"]
		if k == "enemy" or k == "enemy2":
			if e["x"] < 16: e["x"] = 16; e["vx"] = absf(e["vx"])
			elif e["x"] > W - 16: e["x"] = W - 16; e["vx"] = -absf(e["vx"])
			if e["y"] > H + 40: e["dead"] = true
			if rng.randf() < 0.008 + wave * 0.0005:
				entities.append({"kind": "ebullet", "x": e["x"], "y": e["y"] + 10, "vx": 0.0, "vy": 170.0 + wave * 8.0, "hp": 1.0, "r": 3.0, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0})
		elif k == "boss":
			_update_boss(e, dt)
		elif k == "bullet":
			if e["y"] < -40 or e["x"] < -20 or e["x"] > W + 20:
				e["dead"] = true
		elif k == "ebullet":
			if e["y"] > H + 30:
				e["dead"] = true
		elif k == "spark":
			if e["age"] > 0.35:
				e["dead"] = true
		elif k.begins_with("loot"):
			if e["y"] > H + 20:
				e["dead"] = true

	# collisions bullets
	for b in entities:
		if b.get("dead", false) or b["kind"] != "bullet":
			continue
		for en in entities:
			if en.get("dead", false):
				continue
			var ek: String = en["kind"]
			if ek != "enemy" and ek != "enemy2" and ek != "boss" and ek != "rival":
				continue
			if _hit(b, en):
				b["dead"] = true
				en["hp"] = float(en["hp"]) - dmg_mul
				_spark(en["x"], en["y"])
				if float(en["hp"]) <= 0.0:
					en["dead"] = true
					_on_kill(en)
				break

	# loot pickup
	for L in entities:
		if L.get("dead", false):
			continue
		if not str(L["kind"]).begins_with("loot"):
			continue
		if _hit_player(L):
			L["dead"] = true
			score += 20
			_spark(player_x, player_y, 3)

	# damage
	if shield_t <= 0.0:
		for e in entities:
			if e.get("dead", false):
				continue
			var k: String = e["kind"]
			if k != "ebullet" and k != "enemy" and k != "enemy2" and k != "boss" and k != "rival":
				continue
			if _hit_player(e):
				if k == "ebullet":
					e["dead"] = true
				lives -= 1
				shake = 5.0
				shield_t = 1.0
				_spark(player_x, player_y, 10)
				if k != "ebullet" and k != "boss":
					e["y"] = -50.0
				if lives <= 0:
					lives = 0
					game_over = true
					_set_banner("GAME OVER")
				break

	# campaign win
	if mode == "campaign" and not victory and waves_goal > 0:
		var has := false
		for e in entities:
			if e.get("dead", false):
				continue
			var k: String = e["kind"]
			if k == "enemy" or k == "enemy2" or k == "boss":
				has = true
				break
		if wave >= waves_goal and not has:
			victory = true
			game_over = true
			score += 150 + world_id * 60
			_set_banner("ПОБЕДА")

	# arena win
	if mode == "arena" and not game_over:
		var rival_alive := false
		for e in entities:
			if e.get("dead", false):
				continue
			if e["kind"] == "rival":
				rival_alive = true
		if not rival_alive:
			victory = true
			game_over = true
			score += 200
			_set_banner("ПОБЕДА АРЕНЫ")

	# cleanup
	entities = entities.filter(func(e): return not e.get("dead", false))

	for i in stars.size():
		var s: Vector2 = stars[i]
		s.y += 40.0 * dt
		if s.y > H:
			s.y -= H
		stars[i] = s

	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if game_over:
				_finish()
				return
			target_x = st.position.x * (W / get_viewport_rect().size.x)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		target_x = sd.position.x * (W / get_viewport_rect().size.x)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if game_over:
				_finish()
				return
			target_x = mb.position.x * (W / get_viewport_rect().size.x)
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			target_x = event.position.x * (W / get_viewport_rect().size.x)
	if event.is_action_pressed("dash"):
		try_dash()
	if event.is_action_pressed("ult"):
		try_ult()

func try_dash() -> void:
	if dash_cd > 0.0 or game_over:
		return
	dash_cd = 3.2
	dash_t = 0.22
	shield_t = maxf(shield_t, 0.25)
	var dir := signf(target_x - player_x)
	player_x = clampf(player_x + dir * 55.0, 20.0, W - 20.0)
	_spark(player_x, player_y, 8)
	_set_banner("РЫВОК")

func try_ult() -> void:
	if ult_cd > 0.0 or game_over:
		return
	ult_cd = 9.0
	_set_banner("УЛЬТА")
	match hero_id:
		"nova":
			for i in range(-3, 4):
				entities.append({"kind": "bullet", "x": player_x, "y": player_y - 16, "vx": i * 70.0, "vy": -420.0, "hp": 1.0, "r": 3.0, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0})
		"aegis":
			shield_t = 4.0
		"bolt":
			dash_t = 0.5
			shield_t = 2.0
		"shadow":
			shield_t = 2.5
			for i in 3:
				entities.append({"kind": "bullet", "x": player_x, "y": player_y - 16, "vx": 0.0, "vy": -550.0 - i * 30.0, "hp": 1.0, "r": 2.0, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0})
		_:
			for i in 5:
				entities.append({"kind": "bullet", "x": player_x + (i - 2) * 10.0, "y": player_y - 12, "vx": (i - 2) * 25.0, "vy": -380.0 - i * 15.0, "hp": 1.0, "r": 4.0, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0})

func _player_shot() -> void:
	match hero_id:
		"nova":
			for ox in [-8.0, 0.0, 8.0]:
				entities.append({"kind": "bullet", "x": player_x + ox, "y": player_y - 16, "vx": ox * 4.0, "vy": -420.0, "hp": 1.0, "r": 3.0, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0})
		"shadow":
			entities.append({"kind": "bullet", "x": player_x, "y": player_y - 16, "vx": 0.0, "vy": -600.0, "hp": 1.0, "r": 2.0, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0})
		_:
			entities.append({"kind": "bullet", "x": player_x, "y": player_y - 16, "vx": 0.0, "vy": -450.0, "hp": 1.0, "r": 3.0, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0})

func _next_wave(first: bool) -> void:
	wave += 1
	var count := 4 if first else 3 + wave
	for i in count:
		var elite := wave > 2 and rng.randf() < 0.28
		var sy := (30.0 + i * 32.0) if first else (-20.0 - rng.randf() * 90.0)
		entities.append({
			"kind": "enemy2" if elite else "enemy",
			"x": 36 + rng.randf() * (W - 72), "y": sy,
			"vx": (rng.randf() - 0.5) * 55.0, "vy": 65.0 + wave * 7.0 + rng.randf() * 35.0,
			"hp": 3.0 if elite else 1.0, "max_hp": 3.0 if elite else 1.0,
			"r": 14.0 if elite else 12.0, "dead": false, "age": 0.0, "phase": 1
		})
	if wave % 4 == 0 or (mode == "campaign" and wave == waves_goal):
		var hp := 40.0 + wave * 10.0 + world_id * 15.0
		entities.append({
			"kind": "boss", "x": W * 0.5, "y": -50.0, "vx": 0.0, "vy": 28.0,
			"hp": hp, "max_hp": hp, "r": 24.0, "dead": false, "age": 0.0, "phase": 1
		})
		_set_banner("БОСС")

func _update_boss(e: Dictionary, dt: float) -> void:
	var ratio := float(e["hp"]) / maxf(1.0, float(e["max_hp"]))
	var new_phase := 1 if ratio > 0.66 else (2 if ratio > 0.33 else 3)
	if new_phase != int(e["phase"]):
		e["phase"] = new_phase
		_set_banner("ФАЗА %d" % new_phase)
		shake = 4.0
	if e["y"] < 70:
		e["y"] = float(e["y"]) + 22.0 * dt
	e["x"] = float(e["x"]) + sin(float(e["age"]) * (1.5 + e["phase"] * 0.4)) * (35 + e["phase"] * 20) * dt
	e["x"] = clampf(e["x"], 40.0, W - 40.0)
	if rng.randf() < 0.018 + e["phase"] * 0.012:
		for i in int(e["phase"]):
			entities.append({
				"kind": "ebullet", "x": e["x"] + (i - e["phase"] / 2.0) * 12.0, "y": e["y"] + 18,
				"vx": (rng.randf() - 0.5) * 40 * e["phase"], "vy": 160.0 + e["phase"] * 30.0,
				"hp": 1.0, "r": 3.0 + e["phase"] * 0.5, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0
			})

func _spawn_rival() -> void:
	entities.append({
		"kind": "rival", "x": W * 0.5, "y": 80.0, "vx": 0.0, "vy": 0.0,
		"hp": 14.0, "max_hp": 14.0, "r": 14.0, "dead": false, "age": 0.0, "phase": 1
	})

func _update_arena(dt: float) -> void:
	for e in entities:
		if e.get("dead", false) or e["kind"] != "rival":
			continue
		var dx := player_x - float(e["x"])
		e["x"] = float(e["x"]) + signf(dx) * 90.0 * dt
		e["x"] = clampf(e["x"], 30.0, W - 30.0)
		e["age"] = float(e["age"]) + dt
		if fmod(float(e["age"]), 0.45) < dt:
			entities.append({"kind": "ebullet", "x": e["x"], "y": e["y"] + 12, "vx": 0.0, "vy": 220.0, "hp": 1.0, "r": 3.0, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0})

func _on_kill(en: Dictionary) -> void:
	var pts := 300 if en["kind"] == "boss" else (50 if en["kind"] == "enemy2" or en["kind"] == "rival" else 18)
	score += pts
	shake = 4.0 if en["kind"] == "boss" else 2.0
	var drop := rng.randf()
	if drop < 0.5:
		entities.append({"kind": "loot_coin", "x": en["x"], "y": en["y"], "vx": 0.0, "vy": 60.0, "hp": 1.0, "r": 8.0, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0})

func _hit(a: Dictionary, b: Dictionary) -> bool:
	var dx: float = float(a["x"]) - float(b["x"])
	var dy: float = float(a["y"]) - float(b["y"])
	var r: float = float(a["r"]) + float(b["r"])
	return dx * dx + dy * dy < r * r

func _hit_player(e: Dictionary) -> bool:
	var dx: float = float(e["x"]) - player_x
	var dy: float = float(e["y"]) - player_y
	var r: float = float(e["r"]) + 12.0
	return dx * dx + dy * dy < r * r

func _spark(x: float, y: float, n: int = 5) -> void:
	for i in n:
		entities.append({
			"kind": "spark", "x": x, "y": y,
			"vx": (rng.randf() - 0.5) * 150.0, "vy": (rng.randf() - 0.5) * 150.0,
			"hp": 1.0, "r": 2.0, "dead": false, "age": 0.0, "phase": 1, "max_hp": 1.0
		})

func _set_banner(t: String) -> void:
	banner = t
	banner_t = 1.4

func _finish() -> void:
	GameState.add_score(score)
	if victory and mode == "campaign":
		GameState.clear_world(world_id)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _draw() -> void:
	var ox := (rng.randf() - 0.5) * shake * 2.0 if shake > 0.0 else 0.0
	var oy := (rng.randf() - 0.5) * shake * 2.0 if shake > 0.0 else 0.0
	draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)

	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.09))
	for s in stars:
		draw_rect(Rect2(s, Vector2(2, 2)), Color(0.54, 0.6, 0.72))

	for e in entities:
		var p := Vector2(e["x"], e["y"])
		match e["kind"]:
			"bullet":
				draw_rect(Rect2(p - Vector2(1.5, 4.5), Vector2(3, 9)), Color(0.5, 0.82, 1.0))
			"ebullet":
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(1.0, 0.38, 0.5))
			"spark":
				draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1.0, 0.83, 0.29))
			"enemy":
				_draw_ship(p, Color(0.88, 0.25, 0.38), 10)
			"enemy2":
				_draw_ship(p, Color(0.25, 0.75, 0.44), 12)
			"boss":
				var col := Color(0.69, 0.13, 0.25) if int(e["phase"]) == 1 else (Color(1.0, 0.25, 0.25) if int(e["phase"]) == 2 else Color(1.0, 0.83, 0.25))
				_draw_ship(p, col, 18)
				var bw := 60.0
				draw_rect(Rect2(p.x - bw * 0.5, p.y - 30, bw, 5), Color(0.19, 0.06, 0.09))
				draw_rect(Rect2(p.x - bw * 0.5, p.y - 30, bw * clampf(float(e["hp"]) / float(e["max_hp"]), 0, 1), 5), Color(1.0, 0.29, 0.41))
			"rival":
				_draw_ship(p, Color(1.0, 0.69, 0.13), 12)
				var bw2 := 50.0
				draw_rect(Rect2(p.x - bw2 * 0.5, p.y - 24, bw2, 4), Color(0.1, 0.1, 0.15))
				draw_rect(Rect2(p.x - bw2 * 0.5, p.y - 24, bw2 * clampf(float(e["hp"]) / float(e["max_hp"]), 0, 1), 4), Color(1.0, 0.83, 0.29))
			"loot_coin":
				draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color(1.0, 0.83, 0.29))
			_:
				pass

	# player
	var hcol: Color = GameState.HEROES.get(hero_id, {}).get("color", Color(0.29, 0.48, 1.0))
	if shield_t <= 0.0 or tick % 4 < 2:
		_draw_ship(Vector2(player_x, player_y), hcol, 12)

	# HUD
	for i in mini(lives, 6):
		draw_rect(Rect2(10 + i * 14, 10, 10, 10), Color(1.0, 0.29, 0.41))
	draw_string(ThemeDB.fallback_font, Vector2(70, 20), "SCORE %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.91, 0.93, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(200, 20), "W%d" % wave, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.91, 0.93, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(10, H - 28), "DASH %.1f" % dash_cd if dash_cd > 0 else "DASH OK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.29, 1.0, 0.6) if dash_cd <= 0 else Color(0.54, 0.59, 0.69))
	draw_string(ThemeDB.fallback_font, Vector2(100, H - 28), "ULT %.1f" % ult_cd if ult_cd > 0 else "ULT OK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.29, 1.0, 0.6) if ult_cd <= 0 else Color(0.54, 0.59, 0.69))

	if banner_t > 0.0 and banner != "":
		draw_rect(Rect2(W * 0.5 - 100, H * 0.25, 200, 32), Color(0.05, 0.07, 0.13))
		draw_rect(Rect2(W * 0.5 - 100, H * 0.25, 200, 32), Color(1.0, 0.83, 0.29), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 40, H * 0.25 + 22), banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.83, 0.29))

	if game_over:
		draw_rect(Rect2(W * 0.5 - 120, H * 0.5 - 50, 240, 100), Color(0.05, 0.07, 0.13))
		draw_rect(Rect2(W * 0.5 - 120, H * 0.5 - 50, 240, 100), Color(1.0, 0.83, 0.29) if victory else Color(1.0, 0.29, 0.41), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 40, H * 0.5 - 20), "ПОБЕДА" if victory else "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.83, 0.29))
		draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 36, H * 0.5 + 8), "Score %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.91, 0.93, 1.0))
		draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 40, H * 0.5 + 32), "Tap = меню", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.54, 0.59, 0.69))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_ship(p: Vector2, col: Color, s: float) -> void:
	var pts := PackedVector2Array([
		p + Vector2(0, -s),
		p + Vector2(s * 0.7, s * 0.6),
		p + Vector2(0, s * 0.25),
		p + Vector2(-s * 0.7, s * 0.6),
	])
	draw_colored_polygon(pts, col)
	draw_rect(Rect2(p + Vector2(-2, s * 0.5), Vector2(4, 6)), Color(1.0, 0.5, 0.2))
