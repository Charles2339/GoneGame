extends Node2D

const SCENE    := preload("res://scenes/game/Obstacle.tscn")
const GROUND_Y := 960.0
const SPAWN_X  := 2150.0
const OBS_W    := 64.0

# Each pattern: array of [height, gap_to_next] pairs
const PATTERNS: Array = [
	# Tier 1 (easy) ─ index 0-3
	[[ 90.0, 0.0]],
	[[110.0, 0.0]],
	[[ 80.0, 0.0]],
	[[100.0, 480.0], [95.0, 0.0]],
	# Tier 2 (medium) ─ index 4-7
	[[140.0, 0.0]],
	[[ 80.0, 180.0], [120.0, 0.0]],
	[[160.0, 0.0]],
	[[100.0, 250.0], [ 85.0, 0.0]],
	# Tier 3 (hard) ─ index 8-11
	[[180.0, 0.0]],
	[[ 80.0, 140.0], [ 80.0, 140.0], [120.0, 0.0]],
	[[200.0, 0.0]],
	[[120.0, 200.0], [120.0, 0.0]],
]

var _timer    := 0.0
var _interval := 1.9

func reset() -> void:
	_timer    = 0.0
	_interval = 1.9

func _process(delta: float) -> void:
	var main: Node2D = get_parent()
	if not main.game_running:
		return

	var spd: float = main.run_speed

	# Move obstacles & collision
	var player: CharacterBody2D = main.get_node("Player")
	var pp := player.position
	# Hitbox 15% smaller than visual (README §Hitbox forgiveness)
	var margin := OBS_W * 0.15
	var p_rect := Rect2(pp.x - 18.0, pp.y - 40.0, 36.0, 80.0)

	for child in get_children():
		child.position.x -= spd * delta
		if child.position.x < -300.0:
			child.queue_free()
			continue
		var h: float = child.get_meta("height", 100.0)
		var o_rect := Rect2(
			child.position.x + margin,
			child.position.y + 4.0,
			OBS_W - margin * 2.0,
			h - 4.0)
		if p_rect.intersects(o_rect):
			main.on_player_hit()
			return

	# Spawn timer
	_timer += delta
	if _timer >= _interval:
		_timer    = 0.0
		_interval = _next_interval(main)
		_spawn_pattern(main)

func _next_interval(main: Node2D) -> float:
	return maxf(0.65, 1.9 - main.get_difficulty() * 0.38)

func _spawn_pattern(main: Node2D) -> void:
	var diff  := main.get_difficulty()
	var tier  := mini(int(diff), 2)
	var cap   := [3, 7, 11][tier]
	var pat   : Array = PATTERNS[randi() % (cap + 1)]
	var x     := SPAWN_X
	for seg in pat:
		var h: float = seg[0]
		var gap: float = seg[1]
		var obs := SCENE.instantiate()
		obs.set_meta("height", h)
		obs.position = Vector2(x, GROUND_Y - h)
		add_child(obs)
		obs.call("setup", h)
		x += OBS_W + gap
