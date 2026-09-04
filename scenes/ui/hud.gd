extends CanvasLayer

@onready var hp_label: Label = $Control/HPLabel
@onready var round_label: Label = $Control/RoundLabel

var _last_max_hp: int = 100

func _ready() -> void:
	EventBus.player_damaged.connect(_on_player_hp_changed)
	EventBus.player_healed.connect(_on_player_hp_changed)
	EventBus.round_state_changed.connect(_on_round_state_changed)

func bind_player(player: Node) -> void:
	_last_max_hp = player.max_hp
	_update_hp_label(player.hp)

func _on_player_hp_changed(_amount: int, new_hp: int) -> void:
	_update_hp_label(new_hp)

func _update_hp_label(hp: int) -> void:
	hp_label.text = "HP: %d / %d" % [hp, _last_max_hp]

func _on_round_state_changed(_new_state: int, _old_state: int) -> void:
	round_label.text = "Round %d" % RoundManager.current_round
