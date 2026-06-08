extends Node2D
## Draws a 1920-wide tree silhouette strip. Tile width matches scrolling code.

@export var tree_color: Color = Color(0.13, 0.30, 0.18, 1.0)
@export var trunk_color: Color = Color(0.09, 0.18, 0.10, 1.0)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Trees: [x, canopy_height, half_width]
	var trees: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(tree_color))
	# Generate 24 trees spread across 1920px
	for i in 24:
		var x := rng.randf_range(20.0, 1900.0)
		var h := rng.randf_range(120.0, 280.0)
		var hw := h * rng.randf_range(0.28, 0.42)
		trees.append([x, h, hw])
	trees.sort_custom(func(a, b): return a[0] < b[0])

	for tr in trees:
		var x: float  = tr[0]
		var h: float  = tr[1]
		var hw: float = tr[2]
		var base_y := 960.0

		# Trunk
		var tw := hw * 0.16
		draw_rect(Rect2(x - tw * 0.5, base_y - h * 0.28, tw, h * 0.28), trunk_color)

		# Three canopy tiers (bottom to top, each smaller)
		for tier in 3:
			var frac := float(tier) / 3.0
			var ty := base_y - h * (0.22 + frac * 0.55)
			var thw := hw * (1.0 - frac * 0.38)
			var poly := PackedVector2Array([
				Vector2(x - thw, ty + h * 0.22),
				Vector2(x,       ty),
				Vector2(x + thw, ty + h * 0.22),
			])
			var c := tree_color.lightened(frac * 0.07)
			draw_colored_polygon(poly, c)
