extends Node2D

const INITIAL_SPEED := 500.0
const MAX_SPEED     := 950.0
const SPEED_STEP    := 15.0   # px/s per 10 s survival
const BG_TILE_W     := 1920.0
const GND_TILE_W    := 2000.0

var game_running  := false
var game_started  := false
var score         := 0.0
var run_speed     := INITIAL_SPEED
var elapsed       := 0.0
var total_scroll  := 0.0
var high_score    := 0.0
var trauma        := 0.0

@onready var player:      CharacterBody2D = $Player
@onready var cam:         Camera2D        = $Camera2D
@onready var spawner:     Node2D          = $ObstacleSpawner
@onready var score_lbl:   Label           = $HUD/ScoreLabel
@onready var go_panel:    Panel           = $HUD/GameOverPanel
@onready var fs_lbl:      Label           = $HUD/GameOverPanel/VBox/FinalScore
@onready var hs_lbl:      Label           = $HUD/GameOverPanel/VBox/HighScore
@onready var tap_hint:    Label           = $HUD/TapHint
@onready var gnd_a:       Node2D          = $GroundVisuals/GroundA
@onready var gnd_b:       Node2D          = $GroundVisuals/GroundB

# Audio and Particles
var audio_manager: AudioManager
var particle_spawner: ParticleSpawner

# Menu
var main_menu_scene: PackedScene = preload("res://scenes/MainMenu.tscn")

# [node_a_path, node_b_path, factor]
const BG_LAYERS := [
	["BgContainer/Mtn1",    "BgContainer/Mtn2",    0.08],
	["BgContainer/FarT1",   "BgContainer/FarT2",   0.22],
	["BgContainer/NearT1",  "BgContainer/NearT2",  0.48],
]

func _ready() -> void:
	# Initialize audio and particles
	audio_manager = AudioManager.new()
	add_child(audio_manager)
	
	particle_spawner = ParticleSpawner.new()
	add_child(particle_spawner)
	
	# Connect signals
	$HUD/GameOverPanel/VBox/RestartButton.pressed.connect(_on_restart)
	player.landed.connect(_on_land)
	player.jumped.connect(_on_jump)
	player.double_jumped.connect(_on_double_jump)
	player.died.connect(_on_die)
	
	_load_high_score()
	_show_main_menu()

func _show_main_menu() -> void:
	game_running = false
	game_started = false
	if main_menu_scene:
		var menu = main_menu_scene.instantiate()
		add_child(menu)
		menu.play_pressed.connect(_on_menu_play)

func _on_menu_play() -> void:
	_start_game()

func _start_game() -> void:
	game_running = true
	game_started = true
	score        = 0.0
	run_speed    = INITIAL_SPEED
	elapsed      = 0.0
	total_scroll = 0.0
	trauma       = 0.0
	go_panel.visible  = false
	tap_hint.visible  = true
	for c in spawner.get_children():
		c.queue_free()
	spawner.reset()
	player.position = Vector2(200, 800)
	player.velocity = Vector2.ZERO

func get_difficulty() -> float:
	return clampf(1.0 + (elapsed / 60.0) * 2.5, 1.0, 3.5)

func _process(delta: float) -> void:
	if not game_started:
		return
	
	# Camera trauma shake (README §Game Feel)
	trauma = maxf(trauma - 2.8 * delta, 0.0)
	var sh := trauma * trauma
	cam.offset = Vector2(
		randf_range(-14.0, 14.0) * sh,
		randf_range(-7.0,   7.0) * sh)

	if not game_running:
		return

	elapsed      += delta
	score        += delta * 10.0
	run_speed     = minf(INITIAL_SPEED + (elapsed / 10.0) * SPEED_STEP, MAX_SPEED)
	total_scroll += run_speed * delta

	score_lbl.text = "%d" % int(score)
	if score > 6.0:
		tap_hint.visible = false

	# Ground tiles (scroll factor 1.0)
	var gx := -fmod(total_scroll, GND_TILE_W)
	gnd_a.position.x = gx
	gnd_b.position.x = gx + GND_TILE_W

	# Parallax layers
	for data in BG_LAYERS:
		var sx := -fmod(total_scroll * data[2], BG_TILE_W)
		get_node(data[0]).position.x = sx
		get_node(data[1]).position.x = sx + BG_TILE_W

func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)

func on_player_hit() -> void:
	if not game_running:
		return
	game_running = false
	if score > high_score:
		high_score = score
		_save_high_score()
	fs_lbl.text = "Score: %d" % int(score)
	hs_lbl.text = "Best:  %d" % int(high_score)
	player.die()
	add_trauma(0.9)
	if audio_manager:
		audio_manager.play_death()
	_death_sequence()

func _death_sequence() -> void:
	# Hit stop (README §Hit Stop)
	Engine.time_scale = 0.0
	await get_tree().create_timer(0.065, true, false, true).timeout
	Engine.time_scale = 1.0
	await get_tree().create_timer(0.85).timeout
	_show_game_over()

func _show_game_over() -> void:
	go_panel.visible = true
	go_panel.position.y = 180.0
	create_tween().tween_property(go_panel, "position:y", 0.0, 0.38).set_trans(Tween.TRANS_BACK)

func _on_land() -> void:
	add_trauma(0.12)
	if audio_manager:
		audio_manager.play_land_soft()
	if particle_spawner:
		particle_spawner.emit_landing_particles(player.global_position)

func _on_jump() -> void:
	if audio_manager:
		audio_manager.play_jump()

func _on_double_jump() -> void:
	if audio_manager:
		audio_manager.play_double_jump()
	add_trauma(0.1)

func _on_die() -> void:
	add_trauma(0.85)

func _on_restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _load_high_score() -> void:
	var config = ConfigFile.new()
	if config.load("user://gone_save.cfg") == OK:
		high_score = config.get_value("score", "high_score", 0)
		hs_lbl.text = "Best: %d" % int(high_score)

func _save_high_score() -> void:
	var config = ConfigFile.new()
	config.set_value("score", "high_score", int(high_score))
	config.save("user://gone_save.cfg")

