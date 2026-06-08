extends Node2D

class_name PowerUpSpawner

enum PowerUpType { SHIELD, MAGNET, SLOW_MO, SCORE_DOUBLER, NONE }

var active_powerups: Dictionary = {}
var player: CharacterBody2D

signal powerup_collected(type: PowerUpType, duration: float)

func _ready() -> void:
	player = get_parent().get_node("Player")

func spawn_powerup(pos: Vector2, type: PowerUpType = PowerUpType.SHIELD) -> void:
	var size = 24.0
	var color = _get_color_for_type(type)
	
	# Create visual for powerup
	var powerup_node = Node2D.new()
	powerup_node.position = pos
	powerup_node.set_meta("type", type)
	powerup_node.set_meta("size", size)
	powerup_node.set_meta("color", color)
	powerup_node.set_meta("lifetime", 15.0)  # Despawn after 15 seconds
	add_child(powerup_node)

func _process(delta: float) -> void:
	# Update active powerups
	var expired = []
	for key in active_powerups.keys():
		active_powerups[key] -= delta
		if active_powerups[key] <= 0:
			expired.append(key)
	
	for key in expired:
		active_powerups.erase(key)
	
	# Update powerup visual positions and check collisions
	for powerup in get_children():
		if powerup.has_meta("lifetime"):
			var lifetime = powerup.get_meta("lifetime", 1.0)
			lifetime -= delta
			powerup.set_meta("lifetime", lifetime)
			
			if lifetime <= 0:
				powerup.queue_free()
				continue
			
			# Move down slightly and bob
			powerup.position.y += 20.0 * delta
			var bob = sin(Time.get_ticks_msec() * 0.005) * 8.0
			powerup.position.x += cos(Time.get_ticks_msec() * 0.003) * 15.0
			
			# Check collision with player
			if powerup.global_position.distance_to(player.global_position) < 40.0:
				_collect_powerup(powerup)
				powerup.queue_free()

func _collect_powerup(powerup: Node2D) -> void:
	var type: int = powerup.get_meta("type", PowerUpType.NONE)
	var duration = 0.0
	
	match type:
		PowerUpType.SHIELD:
			duration = 15.0
			active_powerups[PowerUpType.SHIELD] = duration
			powerup_collected.emit(PowerUpType.SHIELD, duration)
		PowerUpType.MAGNET:
			duration = 10.0
			active_powerups[PowerUpType.MAGNET] = duration
			powerup_collected.emit(PowerUpType.MAGNET, duration)
		PowerUpType.SLOW_MO:
			duration = 5.0
			active_powerups[PowerUpType.SLOW_MO] = duration
			Engine.time_scale = 0.7
			powerup_collected.emit(PowerUpType.SLOW_MO, duration)
		PowerUpType.SCORE_DOUBLER:
			duration = 10.0
			active_powerups[PowerUpType.SCORE_DOUBLER] = duration
			powerup_collected.emit(PowerUpType.SCORE_DOUBLER, duration)

func has_powerup(type: PowerUpType) -> bool:
	return active_powerups.has(type) and active_powerups[type] > 0

func get_powerup_remaining(type: PowerUpType) -> float:
	if active_powerups.has(type):
		return maxf(0.0, active_powerups[type])
	return 0.0

func _get_color_for_type(type: PowerUpType) -> Color:
	match type:
		PowerUpType.SHIELD: return Color.CYAN
		PowerUpType.MAGNET: return Color.MAGENTA
		PowerUpType.SLOW_MO: return Color(0.5, 0.5, 1.0, 1.0)  # Blue
		PowerUpType.SCORE_DOUBLER: return Color.YELLOW
		_: return Color.WHITE

func _draw() -> void:
	for powerup in get_children():
		if powerup.has_meta("color") and powerup.has_meta("size"):
			var color: Color = powerup.get_meta("color", Color.WHITE)
			var size: float = powerup.get_meta("size", 20.0)
			var lifetime: float = powerup.get_meta("lifetime", 1.0)
			
			# Pulsing effect
			var pulse = sin(Time.get_ticks_msec() * 0.008) * 0.3 + 0.7
			var visual_size = size * pulse
			
			# Draw powerup with glow
			var local_pos = powerup.position - global_position
			draw_circle(local_pos, visual_size, color)
			draw_circle(local_pos, visual_size * 0.6, Color.WHITE)
	queue_redraw()
