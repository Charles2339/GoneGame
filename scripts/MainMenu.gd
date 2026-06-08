extends CanvasLayer

class_name MainMenu

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var vbox: VBoxContainer = $VBoxContainer

signal play_pressed

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	
	# Animate in menu
	vbox.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(vbox, "modulate:a", 1.0, 0.5)
	
	# Subtle title animation
	var orig_scale = title_label.scale
	title_label.scale = orig_scale * 0.8
	var title_tween = create_tween()
	title_tween.set_trans(Tween.TRANS_ELASTIC)
	title_tween.tween_property(title_label, "scale", orig_scale, 0.8)

func _on_play_pressed() -> void:
	# Animate out
	var tween = create_tween()
	tween.tween_property(vbox, "modulate:a", 0.0, 0.3)
	await tween.finished
	play_pressed.emit()
	queue_free()

func _process(delta: float) -> void:
	# Subtle idle animation of buttons
	if play_button:
		var bob = sin(Time.get_ticks_msec() * 0.002) * 5.0
		play_button.position.y = 180.0 + bob
