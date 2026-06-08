extends CharacterBody2D

enum State { RUNNING, JUMPING, FALLING, DEAD }

const GRAVITY        := 2800.0
const JUMP_FORCE     := -900.0
const FALL_MULT      := 1.55     # extra gravity on descent
const COYOTE_TIME    := 0.10
const JUMP_BUFFER    := 0.13
const RUN_PHASE_SPD  := 7.5

var state: State = State.RUNNING
var coyote_timer     := 0.0
var jump_buf_timer   := 0.0
var was_on_floor     := false

@onready var stickman: StickmanDraw = $StickmanDraw

signal landed
signal jumped
signal died

func _input(event: InputEvent) -> void:
	if state == State.DEAD:
		return
	var pressed := false
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		pressed = true
	if pressed:
		jump_buf_timer = JUMP_BUFFER

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	var on_floor := is_on_floor()

	# Coyote time countdown
	coyote_timer     = maxf(coyote_timer     - delta, 0.0)
	jump_buf_timer   = maxf(jump_buf_timer   - delta, 0.0)
	if on_floor:
		coyote_timer = COYOTE_TIME

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
			elif jump_buf_timer > 0.0 and coyote_timer > 0.0:
				_do_jump()

	# Gravity
	if not on_floor:
		var gm := FALL_MULT if velocity.y > 0.0 else 1.0
		velocity.y += GRAVITY * gm * delta

	move_and_slide()

	# Drive run animation
	if state == State.RUNNING:
		stickman.set_run_phase(stickman.run_phase + delta * RUN_PHASE_SPD)

func _set_state(s: State) -> void:
	state = s
	match s:
		State.RUNNING:         stickman.set_state(StickmanDraw.State.RUN)
		State.JUMPING:         stickman.set_state(StickmanDraw.State.JUMP)
		State.FALLING:         stickman.set_state(StickmanDraw.State.FALL)
		State.DEAD:            stickman.set_state(StickmanDraw.State.DEAD)

func _do_jump() -> void:
	velocity.y    = JUMP_FORCE
	jump_buf_timer = 0.0
	coyote_timer   = 0.0
	_set_state(State.JUMPING)
	stickman.trigger_squash(0.72, 1.30)
	jumped.emit()

func _on_land() -> void:
	_set_state(State.RUNNING)
	stickman.trigger_squash(1.32, 0.78)
	landed.emit()

func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	stickman.set_state(StickmanDraw.State.DEAD)
	velocity = Vector2(50.0, -300.0)
	died.emit()
