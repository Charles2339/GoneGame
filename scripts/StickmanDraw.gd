class_name StickmanDraw
extends Node2D

enum State { RUN, JUMP, FALL, DOUBLE_JUMP, SLIDE, DEAD }

var state: State = State.RUN
var run_phase: float = 0.0
var anim_t: float = 0.0   # local timer for state-specific anims
var squash: float = 1.0
var stretch: float = 1.0

const BODY  := Color(0.96, 0.96, 0.96, 1.0)
const DARK  := Color(0.18, 0.18, 0.18, 1.0)
const SHADE := Color(0.70, 0.70, 0.70, 1.0)
const LW    := 5.0
const HR    := 13.0

# Key y-coords in local space (node origin = player center)
const HIP_Y      :=  12.0
const SHLDR_Y    := -22.0
const HEAD_Y     := -38.0
const FOOT_Y     :=  50.0
const UPPER_L    :=  28.0
const LOWER_L    :=  28.0
const ARM_U      :=  20.0
const ARM_L      :=  17.0

func set_state(s: State) -> void:
	if state == s:
		return
	state = s
	anim_t = 0.0

func set_run_phase(t: float) -> void:
	run_phase = t

func trigger_squash(sq: float, st: float) -> void:
	squash = sq
	stretch = st

func _process(delta: float) -> void:
	anim_t += delta
	squash  = move_toward(squash,  1.0, delta * 9.0)
	stretch = move_toward(stretch, 1.0, delta * 9.0)
	scale   = Vector2(stretch, squash)
	# Keep feet pinned at ground
	position.y = FOOT_Y * (1.0 - squash)
	queue_redraw()

func _draw() -> void:
	match state:
		State.RUN:  _draw_run()
		State.JUMP: _draw_jump()
		State.FALL: _draw_fall()
		State.DOUBLE_JUMP: _draw_double_jump()
		State.SLIDE: _draw_slide()
		State.DEAD: _draw_dead()

# ── helpers ──────────────────────────────────────────────────────────────────
func _line(a: Vector2, b: Vector2, w: float = LW) -> void:
	draw_line(a, b, DARK,  w + 2.0)
	draw_line(a, b, BODY,  w)

func _dot(c: Vector2, r: float) -> void:
	draw_circle(c, r + 1.5, DARK)
	draw_circle(c, r, BODY)

# ── RUN ──────────────────────────────────────────────────────────────────────
func _draw_run() -> void:
	var t   := run_phase
	var hip := Vector2(2.0, HIP_Y)
	var shl := Vector2(4.0, SHLDR_Y)   # slight forward lean

	# Legs (left then right, 180° apart)
	for i in 2:
		var ph    := t + i * PI
		var ua    := sin(ph) * 0.72               # thigh swing
		var knee  := hip + Vector2(sin(ua) * UPPER_L, cos(ua) * UPPER_L)
		var bend  := maxf(0.0, sin(ph - PI * 0.45)) * 0.85   # shin bend on back-swing
		var sa    := ua + bend
		var foot  := knee + Vector2(sin(sa) * LOWER_L, cos(sa) * LOWER_L)
		_line(hip, knee)
		_line(knee, foot)

	# Torso
	_line(hip, shl)

	# Arms (opposite phase to legs)
	for i in 2:
		var ph    := t + (1 - i) * PI
		var aa    := sin(ph) * 0.55
		var elbow := shl + Vector2(sin(aa) * ARM_U, absf(cos(aa)) * ARM_U * 0.5 + ARM_U * 0.25)
		var hand  := elbow + Vector2(sin(aa) * ARM_L, ARM_L * 0.4)
		_line(shl, elbow)
		_line(elbow, hand)

	# Head with subtle bob
	var bob := sin(t * 2.0) * 1.8
	_dot(Vector2(4.0, HEAD_Y + bob), HR)
	# Eye
	draw_circle(Vector2(9.0, HEAD_Y + bob - 1.0), 3.0, DARK)

# ── JUMP ─────────────────────────────────────────────────────────────────────
func _draw_jump() -> void:
	var hip := Vector2(0.0, HIP_Y - 5.0)
	var shl := Vector2(0.0, SHLDR_Y)

	# Legs tucked back
	var lk := hip + Vector2(-20.0, 14.0)
	var lf := lk  + Vector2(-8.0,  18.0)
	var rk := hip + Vector2(14.0,  17.0)
	var rf := rk  + Vector2(12.0,  15.0)
	_line(hip, lk); _line(lk, lf)
	_line(hip, rk); _line(rk, rf)

	# Arms raised for balance
	_line(shl, shl + Vector2(-22.0, -20.0))
	_line(shl, shl + Vector2( 22.0, -18.0))
	_line(hip, shl)
	_dot(Vector2(0.0, HEAD_Y - 4.0), HR)
	draw_circle(Vector2(6.0, HEAD_Y - 5.0), 3.0, DARK)

# ── DOUBLE JUMP ──────────────────────────────────────────────────────────────
func _draw_double_jump() -> void:
	var rot := sin(anim_t * 12.0) * 0.3  # spinning animation
	var hip := Vector2(0.0, HIP_Y - 8.0)
	var shl := Vector2(0.0, SHLDR_Y)

	# Legs spread out in kick pose
	var lk := hip + Vector2(-18.0 + sin(rot) * 8, 12.0 + cos(rot) * 8)
	var lf := lk  + Vector2(-22.0, 16.0)
	var rk := hip + Vector2(16.0 - sin(rot) * 8, 14.0 - cos(rot) * 8)
	var rf := rk  + Vector2(20.0, 14.0)
	_line(hip, lk); _line(lk, lf)
	_line(hip, rk); _line(rk, rf)

	# Arms in dynamic pose
	_line(shl, shl + Vector2(-24.0 - sin(rot) * 6, -22.0 + cos(rot) * 8))
	_line(shl, shl + Vector2( 24.0 + sin(rot) * 6, -20.0 - cos(rot) * 8))
	_line(hip, shl)
	_dot(Vector2(sin(rot) * 4.0, HEAD_Y - 6.0), HR)
	draw_circle(Vector2(6.0 + sin(rot) * 3, HEAD_Y - 7.0), 3.0, DARK)

# ── FALL ─────────────────────────────────────────────────────────────────────
func _draw_fall() -> void:
	var hip := Vector2(0.0, HIP_Y + 3.0)
	var shl := Vector2(0.0, SHLDR_Y)

	var lk := hip + Vector2(-16.0, 18.0)
	var lf := lk  + Vector2(-10.0, 22.0)
	var rk := hip + Vector2(12.0,  20.0)
	var rf := rk  + Vector2(10.0,  20.0)
	_line(hip, lk); _line(lk, lf)
	_line(hip, rk); _line(rk, rf)

	# Arms forward/out for stability
	_line(shl, shl + Vector2(-24.0, 8.0))
	_line(shl, shl + Vector2( 24.0, 6.0))
	_line(hip, shl)
	_dot(Vector2(0.0, HEAD_Y), HR)
	draw_circle(Vector2(6.0, HEAD_Y + 1.0), 3.0, DARK)

# ── SLIDE ────────────────────────────────────────────────────────────────────
func _draw_slide() -> void:
	# Body angled forward, low to ground
	var hip := Vector2(8.0,  35.0)
	var shl := Vector2(-18.0, 18.0)

	_line(hip, Vector2(-22.0, 45.0));  _line(Vector2(-22.0, 45.0), Vector2(-35.0, 48.0))
	_line(hip, Vector2(20.0, 42.0));   _line(Vector2(20.0, 42.0), Vector2(34.0, 47.0))
	_line(shl, shl + Vector2(-16.0, 14.0))
	_line(shl, shl + Vector2(12.0,  14.0))
	_line(hip, shl)
	_dot(Vector2(-30.0, 6.0), HR)

# ── DEAD ─────────────────────────────────────────────────────────────────────
func _draw_dead() -> void:
	var p := minf(anim_t * 2.0, 1.0)
	var hip := Vector2(0.0, lerpf(HIP_Y, 44.0, p))
	var shl := Vector2(lerpf(0.0, -14.0, p), lerpf(SHLDR_Y, 26.0, p))

	_line(hip, hip + Vector2(-22.0, lerpf(14.0, 3.0, p)))
	_line(hip + Vector2(-22.0, lerpf(14.0, 3.0, p)),
		  hip + Vector2(-35.0, lerpf(28.0, 6.0, p)))
	_line(hip, hip + Vector2(18.0, 17.0))
	_line(hip + Vector2(18.0, 17.0), hip + Vector2(30.0, 20.0))
	_line(hip, shl)
	_line(shl, shl + Vector2(-20.0, lerpf(-12.0, 15.0, p)))
	_line(shl, shl + Vector2(16.0,  lerpf(-10.0, 18.0, p)))
	_dot(shl + Vector2(-10.0, lerpf(-14.0, -12.0, p)), HR)
	# X eyes
	if p > 0.5:
		var hc := shl + Vector2(-10.0, lerpf(-14.0, -12.0, p))
		draw_line(hc + Vector2(-6,-6), hc + Vector2(6, 6), DARK, 2.5)
		draw_line(hc + Vector2( 6,-6), hc + Vector2(-6,6), DARK, 2.5)
