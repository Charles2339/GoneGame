extends Node2D

func setup(height: float) -> void:
	$Visual.set_deferred("size", Vector2(70.0, height))
