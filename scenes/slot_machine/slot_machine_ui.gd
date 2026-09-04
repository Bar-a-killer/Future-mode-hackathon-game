extends CanvasLayer

@onready var panel: Control = $Panel
@onready var buttons: Array[Button] = [$Panel/Button1, $Panel/Button2, $Panel/Button3]

var _choices: Array[ItemData] = []

func _ready() -> void:
	panel.visible = false
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_button_pressed.bind(i))

func show_choices(choices: Array[ItemData]) -> void:
	_choices = choices
	for i in range(buttons.size()):
		var item := choices[i]
		buttons[i].text = "%s\n%s" % [item.display_name, item.description]
	panel.visible = true

func _on_button_pressed(index: int) -> void:
	panel.visible = false
	EventBus.item_selected.emit(_choices[index])
