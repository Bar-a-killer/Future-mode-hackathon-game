extends CanvasLayer

const FADE_TIME := 0.35

@onready var panel: Control = $Panel
@onready var label: Label = $Panel/Label
@onready var score_label: Label = $Panel/ScoreLabel
@onready var restart_button: Button = $Panel/RestartButton

func _ready() -> void:
	panel.visible = false
	EventBus.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)

func _on_game_over() -> void:
	score_label.text = "Score %d" % Wallet.score
	panel.visible = true
	panel.modulate.a = 0.0
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(1.25, 1.25)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, FADE_TIME)
	var settle := tween.tween_property(label, "scale", Vector2.ONE, FADE_TIME)
	settle.set_trans(Tween.TRANS_BACK)
	settle.set_ease(Tween.EASE_OUT)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
