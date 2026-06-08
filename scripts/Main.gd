extends Node2D

var game_running := false
var score := 0.0
var run_speed := 600.0
var _high_score := 0.0

@onready var score_label: Label = $HUD/ScoreLabel
@onready var game_over_panel: Panel = $HUD/GameOverPanel
@onready var final_score_label: Label = $HUD/GameOverPanel/VBox/FinalScore
@onready var high_score_label: Label = $HUD/GameOverPanel/VBox/HighScore
@onready var obstacle_spawner: Node2D = $ObstacleSpawner
@onready var tap_hint: Label = $HUD/TapHint

func _ready() -> void:
	$HUD/GameOverPanel/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	_start_game()

func _start_game() -> void:
	game_running = true
	score = 0.0
	run_speed = 600.0
	game_over_panel.visible = false
	tap_hint.visible = true
	for child in obstacle_spawner.get_children():
		child.queue_free()
	obstacle_spawner.reset()

func _process(delta: float) -> void:
	if not game_running:
		return
	score += delta * 10.0
	run_speed = minf(600.0 + score * 2.0, 1800.0)
	score_label.text = "Score: %d" % int(score)
	if score > 5.0:
		tap_hint.visible = false

func on_player_hit() -> void:
	if not game_running:
		return
	game_running = false
	if score > _high_score:
		_high_score = score
	final_score_label.text = "Score: %d" % int(score)
	high_score_label.text = "Best:  %d" % int(_high_score)
	game_over_panel.visible = true

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
