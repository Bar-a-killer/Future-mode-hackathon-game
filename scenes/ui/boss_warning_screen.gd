extends CanvasLayer

const FADE_TIME := 0.4
const DISPLAY_TIME := 1.2

@onready var panel: Control = $Panel
@onready var label: Label = $Panel/Label

func _ready() -> void:
	panel.visible = false
	EventBus.boss_warning.connect(_on_boss_warning)

func _on_boss_warning() -> void:
	panel.visible = true
	label.modulate.a = 0.0
	label.scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, FADE_TIME)
	var pop := tween.tween_property(label, "scale", Vector2(1.2, 1.2), FADE_TIME)
	pop.set_trans(Tween.TRANS_BACK)
	pop.set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(DISPLAY_TIME)
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, FADE_TIME)
	tween.tween_property(label, "scale", Vector2(0.8, 0.8), FADE_TIME)
	tween.chain().tween_callback(func(): panel.visible = false)
