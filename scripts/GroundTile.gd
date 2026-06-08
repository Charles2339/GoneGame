extends Node2D
## Draws a 2000-wide ground tile: grass strip on top, textured dirt below.
## Position this node at y=960 (ground level). Grass grows upward.

const GRASS_TOP   := Color(0.30, 0.65, 0.28, 1.0)
const GRASS_MID   := Color(0.22, 0.52, 0.22, 1.0)
const DIRT_BASE   := Color(0.36, 0.24, 0.13, 1.0)
const DIRT_DARK   := Color(0.26, 0.16, 0.08, 1.0)
const DIRT_LIGHT  := Color(0.45, 0.31, 0.17, 1.0)
const W           := 2000.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Grass: y= -22 to +6 (relative to node at y=960 → world y 938–966)
	draw_rect(Rect2(0.0, -22.0, W, 28.0), GRASS_MID)
	draw_rect(Rect2(0.0, -22.0, W,  6.0), GRASS_TOP)    # bright blade tips

	# Dirt body
	draw_rect(Rect2(0.0, 6.0, W, 120.0), DIRT_BASE)

	# Subtle horizontal strata lines
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var y := 14.0
	while y < 120.0:
		var lw := rng.randf_range(60.0, 180.0)
		var lx := rng.randf_range(0.0, W - lw)
		var col := DIRT_DARK if rng.randf() < 0.5 else DIRT_LIGHT
		draw_rect(Rect2(lx, y, lw, 3.0), col)
		y += rng.randf_range(8.0, 18.0)

	# Pebbles
	rng.seed = 99
	for _i in 18:
		var px := rng.randf_range(10.0, W - 10.0)
		var py := rng.randf_range(10.0, 80.0)
		var pr := rng.randf_range(3.0, 6.0)
		draw_circle(Vector2(px, py), pr, DIRT_DARK)
