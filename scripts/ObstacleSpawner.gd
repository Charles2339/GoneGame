extends Node2D

const OBSTACLE_SCENE := preload("res://scenes/game/Obstacle.tscn")
const GROUND_Y := 960.0
const OBSTACLE_WIDTH := 70.0

var _timer := 0.0
var _interval := 1.8

func reset() -> void:
	_timer = 0.0
	_interval = 1.8

func _process(delta: float) -> void:
	var main: Node2D = get_parent()
	if not main.game_running:
		return

	var spd: float = main.run_speed

	# Move obstacles and check collision
	var player: CharacterBody2D = main.get_node("Player")
	var p := player.position
	# Forgiving hit rect (smaller than visual)
	var p_rect := Rect2(p.x - 22.0, p.y - 44.0, 44.0, 88.0)

	for child in get_children():
		child.position.x -= spd * delta
		if child.position.x < -300.0:
			child.queue_free()
			continue
		# AABB collision check
		var h: float = child.get_meta("height")
		var o_rect := Rect2(child.position.x + 5.0, child.position.y + 5.0, OBSTACLE_WIDTH - 10.0, h - 5.0)
		if p_rect.intersects(o_rect):
			main.on_player_hit()
			return

	# Spawn new obstacles
	_timer += delta
	if _timer >= _interval:
		_timer = 0.0
		_interval = maxf(0.65, _interval - 0.02)
		_spawn()

func _spawn() -> void:
	var obs = OBSTACLE_SCENE.instantiate()
	var heights := [80.0, 120.0, 160.0, 200.0]
	var h: float = heights[randi() % heights.size()]
	obs.set_meta("height", h)
	obs.position = Vector2(2150.0, GROUND_Y - h)
	obs.call("setup", h)
	add_child(obs)
