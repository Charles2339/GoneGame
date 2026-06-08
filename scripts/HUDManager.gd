extends CanvasLayer

class_name HUDManager

@onready var score_label: Label = $ScoreLabel
@onready var combo_label: Label = $ComboLabel
@onready var multiplier_label: Label = $MultiplierLabel
@onready var tap_hint: Label = $TapHint

var last_score: float = 0.0
var combo_count: int = 0
var score_multiplier: float = 1.0

func _ready() -> void:
	combo_label.visible = false
	multiplier_label.visible = false

func update_score(current_score: float) -> void:
	if current_score > last_score:
		# Animate score increase
		var increase = current_score - last_score
		score_label.text = "%d" % int(current_score)
		
		# Pulse animation on large increases
		if increase > 100:
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_ELASTIC)
			var orig_scale = score_label.scale
			score_label.scale = orig_scale * 0.7
			tween.tween_property(score_label, "scale", orig_scale, 0.4)
	
	last_score = current_score

func show_combo(count: int) -> void:
	combo_count = count
	combo_label.visible = count > 1
	if count > 1:
		combo_label.text = "COMBO x%d" % count
		# Color based on combo
		if count >= 3:
			combo_label.add_theme_color_override("font_color", Color.YELLOW)
		elif count >= 2:
			combo_label.add_theme_color_override("font_color", Color.ORANGE)

func show_multiplier(mult: float) -> void:
	score_multiplier = mult
	if mult > 1.0:
		multiplier_label.visible = true
		multiplier_label.text = "x%.1f" % mult
		multiplier_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		multiplier_label.visible = false

func play_score_float(text: String, color: Color = Color.WHITE) -> void:
	# Create floating text animation
	var label = Label.new()
	add_child(label)
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.position = Vector2(get_viewport_rect().size.x * 0.5, 100)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", 50.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	await tween.finished
	label.queue_free()

func hide_tap_hint() -> void:
	if tap_hint:
		var tween = create_tween()
		tween.tween_property(tap_hint, "modulate:a", 0.0, 0.5)
