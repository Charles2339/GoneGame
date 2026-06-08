extends Node2D

const SCENE    := preload("res://scenes/game/Obstacle.tscn")
const GROUND_Y := 960.0
const SPAWN_X  := 2150.0
const OBS_W    := 64.0

# Enhanced obstacle patterns - [height, gap]
const PATTERNS: Array = [
	# Tier 0: Easy - single obstacles
	[[ 90.0, 0.0]],
	[[110.0, 0.0]],
	[[ 80.0, 0.0]],
	[[100.0, 0.0]],
	[[95.0, 0.0]],
	[[140.0, 0.0]],
	[[120.0, 0.0]],
	
	# Tier 1: Medium - combinations
	[[100.0, 480.0], [95.0, 0.0]],
	[[ 80.0, 180.0], [120.0, 0.0]],
	[[100.0, 250.0], [ 85.0, 0.0]],
	[[ 80.0, 140.0], [ 80.0, 140.0], [120.0, 0.0]],
	[[120.0, 200.0], [120.0, 0.0]],
	[[140.0, 300.0], [90.0, 0.0]],
	[[110.0, 150.0], [110.0, 0.0]],
	[[100.0, 100.0], [100.0, 100.0], [100.0, 0.0]],
	[[160.0, 250.0], [80.0, 0.0]],
	[[90.0, 180.0], [110.0, 180.0], [95.0, 0.0]],
	[[130.0, 200.0], [85.0, 0.0]],
	
	# Tier 2: Hard - dense obstacles
	[[180.0, 0.0]],
	[[200.0, 0.0]],
	[[150.0, 100.0], [150.0, 100.0], [100.0, 0.0]],
	[[120.0, 80.0], [120.0, 80.0], [120.0, 0.0]],
	[[160.0, 120.0], [160.0, 0.0]],
	[[100.0, 50.0], [100.0, 50.0], [100.0, 50.0], [100.0, 0.0]],
	[[140.0, 80.0], [90.0, 80.0], [140.0, 0.0]],
	[[170.0, 140.0], [85.0, 0.0]],
	[[110.0, 70.0], [110.0, 70.0], [110.0, 70.0], [100.0, 0.0]],
	[[150.0, 60.0], [150.0, 0.0]],
	[[190.0, 100.0], [80.0, 0.0]],
	[[120.0, 90.0], [120.0, 90.0], [90.0, 0.0]],
	[[140.0, 70.0], [140.0, 70.0], [100.0, 0.0]],
]

var _timer: float    = 0.0
var _interval: float = 1.9

func reset() -> void:
	_timer    = 0.0
	_interval = 1.9

func _process(delta: float) -> void:
	var main = get_parent()
	if not main.game_running:
		return

	var spd: float = main.run_speed

	var player: CharacterBody2D = main.get_node("Player")
	var pp: Vector2 = player.position
	var margin: float = OBS_W * 0.15
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

	_timer += delta
	if _timer >= _interval:
		_timer = 0.0
		var diff: float = main.get_difficulty()
		# Difficulty scales the spawn rate and obstacle toughness
		_interval = maxf(0.50, 1.9 - diff * 0.48)
		_spawn_pattern(diff)

func _spawn_pattern(diff: float) -> void:
	var tier: int = mini(int(diff), 2)
	
	# Tier caps expanded for more variety
	var tier_caps: Array = [
		6,    # Tier 0: patterns 0-6
		17,   # Tier 1: patterns 7-17
		32,   # Tier 2: patterns 18-32
	]
	
	var cap: int = tier_caps[tier]
	var min_idx: int = 0
	
	# Calculate starting index for this tier
	if tier > 0:
		min_idx = tier_caps[tier - 1] + 1
	
	# Blend between tiers for smoother difficulty curve
	if diff > 1.0 and tier > 0:
		# Chance to pick from previous tier
		var blend_chance = 0.3 * (2.0 - diff)  # Higher blend early in tier
		if randf() < blend_chance:
			cap = tier_caps[tier - 1]
			min_idx = 0
	
	var pat: Array = PATTERNS[randi_range(min_idx, cap)]
	var x: float = SPAWN_X
	for seg in pat:
		var h: float = float(seg[0])
		var gap: float = float(seg[1])
		var obs := SCENE.instantiate()
		obs.set_meta("height", h)
		obs.position = Vector2(x, GROUND_Y - h)
		add_child(obs)
		obs.call("setup", h)
		x += OBS_W + gap

