extends Node2D

class_name ParticleSpawner

var particles_pool: Array = []
const PARTICLE_COUNT = 50

func _ready() -> void:
	# Pre-allocate simple particles for pooling
	for i in range(PARTICLE_COUNT):
		var p = Node2D.new()
		p.visible = false
		add_child(p)
		particles_pool.append(p)

func emit_landing_particles(pos: Vector2) -> void:
	var count = randi_range(6, 10)
	for i in range(count):
		var angle = (PI * 2.0 / count) * i + randf_range(-0.3, 0.3)
		var speed = randf_range(200.0, 350.0)
		var vel = Vector2(cos(angle), sin(angle)) * speed
		_spawn_particle(pos, vel, randf_range(0.3, 0.6), Color(0.8, 0.75, 0.7, 0.8))

func emit_jump_particles(pos: Vector2) -> void:
	var count = randi_range(3, 5)
	for i in range(count):
		var angle = randf_range(-PI * 0.3, PI * 0.3) - PI * 0.5
		var speed = randf_range(150.0, 250.0)
		var vel = Vector2(cos(angle), sin(angle)) * speed
		_spawn_particle(pos, vel, randf_range(0.2, 0.4), Color(0.85, 0.8, 0.75, 0.7))

func emit_double_jump_particles(pos: Vector2) -> void:
	var count = 8
	for i in range(count):
		var angle = (PI * 2.0 / count) * i
		var speed = randf_range(250.0, 400.0)
		var vel = Vector2(cos(angle), sin(angle)) * speed
		_spawn_particle(pos, vel, randf_range(0.3, 0.6), Color(1.0, 0.8, 0.2, 0.9))

func emit_death_particles(pos: Vector2) -> void:
	var count = randi_range(15, 25)
	for i in range(count):
		var angle = randf_range(0.0, PI * 2.0)
		var speed = randf_range(300.0, 600.0)
		var vel = Vector2(cos(angle), sin(angle)) * speed
		var color = Color.from_hsv(randf_range(0.0, 0.1), randf_range(0.6, 1.0), 1.0, 0.9)
		_spawn_particle(pos, vel, randf_range(0.4, 0.8), color)

func emit_running_dust(pos: Vector2) -> void:
	var angle = randf_range(PI * 0.9, PI * 1.1)
	var speed = randf_range(80.0, 150.0)
	var vel = Vector2(cos(angle), sin(angle)) * speed
	_spawn_particle(pos, vel, randf_range(0.3, 0.5), Color(0.75, 0.7, 0.65, 0.5))

func emit_coin_particles(pos: Vector2, color: Color = Color.YELLOW) -> void:
	var count = 6
	for i in range(count):
		var angle = (PI * 2.0 / count) * i + randf_range(-0.2, 0.2)
		var speed = randf_range(200.0, 350.0)
		var vel = Vector2(cos(angle), sin(angle)) * speed
		_spawn_particle(pos, vel, randf_range(0.3, 0.5), color)

# Internal particle spawning
func _spawn_particle(pos: Vector2, vel: Vector2, lifetime: float, color: Color) -> void:
	if particles_pool.is_empty():
		var p = Node2D.new()
		add_child(p)
		particles_pool.append(p)
	
	var particle = particles_pool.pop()
	particle.position = pos
	particle.visible = true
	
	# Store particle data as metadata for _process to handle
	particle.set_meta("vel", vel)
	particle.set_meta("lifetime", lifetime)
	particle.set_meta("color", color)
	particle.set_meta("max_lifetime", lifetime)
	particle.set_meta("size", randf_range(3.0, 8.0))

func _process(delta: float) -> void:
	for particle in get_children():
		if not particle.visible:
			continue
		
		if not particle.has_meta("lifetime"):
			continue
		
		var lifetime = particle.get_meta("lifetime", 0.0)
		lifetime -= delta
		
		if lifetime <= 0.0:
			particle.visible = false
			particles_pool.append(particle)
			continue
		
		particle.set_meta("lifetime", lifetime)
		
		var vel: Vector2 = particle.get_meta("vel", Vector2.ZERO)
		var gravity = 1500.0
		vel.y += gravity * delta
		particle.set_meta("vel", vel)
		particle.position += vel * delta
		
		# Visual update
		queue_redraw()

func _draw() -> void:
	for particle in get_children():
		if not particle.visible:
			continue
		
		if not particle.has_meta("color"):
			continue
		
		var color: Color = particle.get_meta("color", Color.WHITE)
		var size: float = particle.get_meta("size", 5.0)
		var lifetime: float = particle.get_meta("lifetime", 0.0)
		var max_lifetime: float = particle.get_meta("max_lifetime", 1.0)
		
		# Fade out at end
		var alpha = clampf(color.a * (lifetime / max_lifetime), 0.0, 1.0)
		color.a = alpha
		
		# Draw particle
		var local_pos = particle.position - global_position
		draw_circle(local_pos, size, color)
