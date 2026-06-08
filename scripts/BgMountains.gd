extends Node2D
## Draws a 1920-wide mountain silhouette strip that tiles horizontally.
## Does not need to redraw every frame – static geometry.

const MTN_COLOR := Color(0.095, 0.195, 0.145, 1.0)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Mountains defined as peak (px, py) with half-width hw
	var peaks := [
		[160.0,  680.0, 220.0],
		[520.0,  520.0, 310.0],
		[900.0,  580.0, 280.0],
		[1260.0, 500.0, 340.0],
		[1660.0, 560.0, 290.0],
		[1980.0, 620.0, 260.0],   # bleeds into next tile
	]
	for pk in peaks:
		var px: float = pk[0]
		var py: float = pk[1]
		var hw: float = pk[2]
		var poly := PackedVector2Array([
			Vector2(px - hw, 960.0),
			Vector2(px,      py),
			Vector2(px + hw, 960.0),
		])
		draw_colored_polygon(poly, MTN_COLOR)
