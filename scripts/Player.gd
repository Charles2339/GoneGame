extends CharacterBody2D

const JUMP_VELOCITY := -1400.0
const GRAVITY := 3500.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()

func try_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		try_jump()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		try_jump()
