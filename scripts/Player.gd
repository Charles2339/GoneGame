extends CharacterBody2D

enum State { RUNNING, JUMPING, FALLING, DOUBLE_JUMPING, SLIDING, DEAD }

const GRAVITY           := 2800.0
const JUMP_FORCE        := -900.0
const DOUBLE_JUMP_FORCE := -750.0
const FALL_MULT         := 1.55     # extra gravity on descent
const FALL_MULT_SHORT   := 1.0      # lighter gravity on short jumps
const COYOTE_TIME       := 0.10
const JUMP_BUFFER       := 0.13
const RUN_PHASE_SPD     := 7.5
const SLIDE_DURATION    := 0.5
const EARLY_FALL_MULT   := 2.5      # gravity multiplier when releasing jump early

var state: State = State.RUNNING
var coyote_timer        := 0.0
var jump_buf_timer      := 0.0
var was_on_floor        := false
var can_double_jump     := false
var jump_held_time      := 0.0
var slide_timer         := 0.0

@onready var stickman: StickmanDraw = $StickmanDraw
@onready var collision: CollisionShape2D = $CollisionShape2D

signal landed
signal jumped
signal double_jumped
signal died
signal slide_started
signal slide_ended

func _input(event: InputEvent) -> void:
	if state == State.DEAD:
		return
	
	var pressed := false
	var released := false
	
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
	elif event is InputEventScreenTouch and not event.pressed:
		released = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		pressed = true
	elif event is InputEventKey and not event.pressed and event.keycode == KEY_SPACE:
		released = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_S:
		# S key for slide
		if state in [State.RUNNING, State.JUMPING, State.FALLING]:
			_start_slide()
	
	if pressed:
		jump_buf_timer = JUMP_BUFFER
		jump_held_time = 0.0
	
	if released:
		# Early jump release for variable height
		if state in [State.JUMPING, State.DOUBLE_JUMPING] and velocity.y < 0:
			velocity.y *= 0.5

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	var on_floor := is_on_floor()

	# Coyote time countdown
	coyote_timer     = maxf(coyote_timer     - delta, 0.0)
	jump_buf_timer   = maxf(jump_buf_timer   - delta, 0.0)
	jump_held_time   = maxf(jump_held_time   - delta, 0.0)
	
	if on_floor:
		coyote_timer = COYOTE_TIME
		can_double_jump = true
		slide_timer = 0.0
	
	# Sliding
	if state == State.SLIDING:
		slide_timer -= delta
		if slide_timer <= 0.0:
			_end_slide()

	# Landing
	if on_floor and not was_on_floor:
		_on_land()
	was_on_floor = on_floor

	# State transitions
	match state:
		State.RUNNING:
			if not on_floor:
				_set_state(State.FALLING)
			elif jump_buf_timer > 0.0:
				_do_jump()

		State.JUMPING:
			if velocity.y >= 0.0:
				_set_state(State.FALLING)

		State.FALLING:
			if on_floor:
				_set_state(State.RUNNING)
			elif jump_buf_timer > 0.0 and can_double_jump:
				_do_double_jump()
			elif jump_buf_timer > 0.0 and coyote_timer > 0.0:
				_do_jump()

		State.DOUBLE_JUMPING:
			if velocity.y >= 0.0:
				_set_state(State.FALLING)

		State.SLIDING:
			if not on_floor:
				_set_state(State.FALLING)

	# Gravity with variable multiplier
	if not on_floor:
		var gm := EARLY_FALL_MULT if velocity.y > 0.0 and velocity.y > 0.1 else 1.0
		velocity.y += GRAVITY * gm * delta

	move_and_slide()

	# Drive run animation
	if state == State.RUNNING:
		stickman.set_run_phase(stickman.run_phase + delta * RUN_PHASE_SPD)
		# Emit running dust every other footstep
		if int(stickman.run_phase) % 2 == 0 and int(stickman.run_phase + delta * RUN_PHASE_SPD) % 2 != 0:
			_emit_running_dust()

func _set_state(s: State) -> void:
	state = s
	match s:
		State.RUNNING:         stickman.set_state(StickmanDraw.State.RUN)
		State.JUMPING:         stickman.set_state(StickmanDraw.State.JUMP)
		State.FALLING:         stickman.set_state(StickmanDraw.State.FALL)
		State.DOUBLE_JUMPING:  stickman.set_state(StickmanDraw.State.DOUBLE_JUMP)
		State.SLIDING:         stickman.set_state(StickmanDraw.State.SLIDE)
		State.DEAD:            stickman.set_state(StickmanDraw.State.DEAD)

func _do_jump() -> void:
	velocity.y    = JUMP_FORCE
	jump_buf_timer = 0.0
	coyote_timer   = 0.0
	jump_held_time = 0.08
	_set_state(State.JUMPING)
	stickman.trigger_squash(0.72, 1.30)
	_emit_jump_particles()
	jumped.emit()

func _do_double_jump() -> void:
	velocity.y = DOUBLE_JUMP_FORCE
	jump_buf_timer = 0.0
	can_double_jump = false
	jump_held_time = 0.08
	_set_state(State.DOUBLE_JUMPING)
	stickman.trigger_squash(0.75, 1.25)
	_emit_double_jump_particles()
	double_jumped.emit()

func _start_slide() -> void:
	if state == State.SLIDING:
		return
	_set_state(State.SLIDING)
	slide_timer = SLIDE_DURATION
	stickman.trigger_squash(1.4, 0.65)
	slide_started.emit()
	
	# Shrink collision for slide
	if collision:
		var original_scale = collision.scale
		var tween = create_tween()
		tween.tween_property(collision, "scale:y", 0.6, 0.05)

func _end_slide() -> void:
	if state != State.SLIDING:
		return
	var new_state = State.FALLING if not is_on_floor() else State.RUNNING
	_set_state(new_state)
	
	# Restore collision
	if collision:
		var tween = create_tween()
		tween.tween_property(collision, "scale:y", 1.0, 0.1)
	
	slide_ended.emit()

func _on_land() -> void:
	_set_state(State.RUNNING)
	stickman.trigger_squash(1.32, 0.78)
	_emit_landing_particles()
	landed.emit()

func _emit_jump_particles() -> void:
	if has_node("../ParticleSpawner"):
		var spawner = get_parent().get_node("ParticleSpawner")
		if spawner:
			spawner.emit_jump_particles(global_position)

func _emit_double_jump_particles() -> void:
	if has_node("../ParticleSpawner"):
		var spawner = get_parent().get_node("ParticleSpawner")
		if spawner:
			spawner.emit_double_jump_particles(global_position)

func _emit_landing_particles() -> void:
	if has_node("../ParticleSpawner"):
		var spawner = get_parent().get_node("ParticleSpawner")
		if spawner:
			spawner.emit_landing_particles(global_position)

func _emit_running_dust() -> void:
	if has_node("../ParticleSpawner"):
		var spawner = get_parent().get_node("ParticleSpawner")
		if spawner:
			spawner.emit_running_dust(global_position)

func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	stickman.set_state(StickmanDraw.State.DEAD)
	velocity = Vector2(50.0, -300.0)
	
	# Emit death particles
	if has_node("../ParticleSpawner"):
		var spawner = get_parent().get_node("ParticleSpawner")
		if spawner:
			spawner.emit_death_particles(global_position)
	
	died.emit()
