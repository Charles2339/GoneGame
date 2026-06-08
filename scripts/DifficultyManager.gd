extends Node

class_name DifficultyManager

# Difficulty scaling configuration
const INITIAL_SPEED := 500.0
const MAX_SPEED := 950.0
const BASE_SPAWN_INTERVAL := 1.9

var elapsed_time: float = 0.0
var current_difficulty: float = 1.0
var score_multiplier: float = 1.0

signal difficulty_changed(new_difficulty: float)
signal difficulty_milestone(milestone: int)

func _ready() -> void:
	pass

func update(delta: float) -> void:
	elapsed_time += delta
	
	# Calculate difficulty curve
	var new_difficulty = clampf(1.0 + (elapsed_time / 60.0) * 2.5, 1.0, 3.5)
	
	if new_difficulty != current_difficulty:
		current_difficulty = new_difficulty
		difficulty_changed.emit(current_difficulty)
		
		# Emit milestone signals
		var milestone = int(current_difficulty)
		if milestone > int(current_difficulty - 0.1):
			difficulty_milestone.emit(milestone)

func get_difficulty() -> float:
	return current_difficulty

func get_spawn_interval(base_interval: float = BASE_SPAWN_INTERVAL) -> float:
	return maxf(0.50, base_interval - current_difficulty * 0.48)

func get_speed() -> float:
	return INITIAL_SPEED + (elapsed_time / 10.0) * 15.0

func get_max_speed() -> float:
	return MAX_SPEED

func get_score_multiplier() -> float:
	# Score multiplier increases with difficulty
	return 1.0 + (current_difficulty - 1.0) * 0.5

func reset() -> void:
	elapsed_time = 0.0
	current_difficulty = 1.0
	score_multiplier = 1.0
