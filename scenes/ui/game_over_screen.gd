extends CanvasLayer

@onready var panel: Control = $Panel
@onready var restart_button: Button = $Panel/RestartButton

func _ready() -> void:
	panel.visible = false
	EventBus.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)

func _on_game_over() -> void:
	panel.visible = true

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
