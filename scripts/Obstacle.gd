extends Node2D

func setup(height: float) -> void:
	set_meta("height", height)
	queue_redraw()

func _draw() -> void:
	var h: float = get_meta("height", 100.0)
	var w := 64.0

	# Drop shadow
	draw_rect(Rect2(5.0, 5.0, w, h), Color(0.0, 0.0, 0.0, 0.28))

	# Main pillar body (dark stone)
	draw_rect(Rect2(0.0, 0.0, w, h), Color(0.28, 0.22, 0.16, 1.0))

	# Hazard stripes
	var stripe_h := 18.0
	var y := 8.0
	var toggle := true
	while y < h - 4.0:
		var sh := minf(stripe_h, h - y - 4.0)
		if toggle:
			draw_rect(Rect2(6.0, y, w - 12.0, sh), Color(0.85, 0.48, 0.08, 0.55))
		toggle = not toggle
		y += stripe_h

	# Left highlight edge
	draw_rect(Rect2(0.0, 0.0, 6.0, h), Color(0.55, 0.42, 0.26, 1.0))
	# Right dark edge
	draw_rect(Rect2(w - 6.0, 0.0, 6.0, h), Color(0.16, 0.11, 0.07, 1.0))

	# Top cap (gold bar)
	draw_rect(Rect2(-5.0, -12.0, w + 10.0, 14.0), Color(0.88, 0.66, 0.12, 1.0))
	draw_rect(Rect2(-5.0, -12.0, w + 10.0,  4.0), Color(1.00, 0.85, 0.35, 1.0))

	# Spikes on top
	var n_spikes := 3
	var sx_start := 8.0
	var sx_step  := (w - 16.0) / float(n_spikes - 1)
	for i in n_spikes:
		var sx := sx_start + i * sx_step
		var spike := PackedVector2Array([
			Vector2(sx - 9.0, -12.0),
			Vector2(sx,       -30.0),
			Vector2(sx + 9.0, -12.0),
		])
		draw_colored_polygon(spike, Color(0.96, 0.75, 0.18, 1.0))
		# Spike highlight
		draw_line(Vector2(sx - 9.0, -12.0), Vector2(sx, -30.0), Color(1.0, 0.92, 0.55, 0.7), 2.0)
