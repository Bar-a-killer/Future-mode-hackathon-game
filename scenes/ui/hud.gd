extends CanvasLayer

const HP_BAR_WIDTH := 308.0
const HP_TWEEN_TIME := 0.25
const HP_FULL_COLOR := Color(0.29, 0.87, 0.55)
const HP_WARN_COLOR := Color(1.0, 0.78, 0.25)
const HP_LOW_COLOR := Color(1.0, 0.32, 0.36)

@onready var hp_label: Label = $Control/Panel/HpTrack/HPLabel
@onready var hp_fill: ColorRect = $Control/Panel/HpTrack/HpFill
@onready var round_label: Label = $Control/Panel/RoundLabel
@onready var score_label: Label = $Control/Panel/ScoreLabel

var _last_max_hp: int = 100
var _hp_tween: Tween

func _ready() -> void:
	EventBus.player_damaged.connect(_on_player_hp_changed)
	EventBus.player_healed.connect(_on_player_hp_changed)
	EventBus.round_state_changed.connect(_on_round_state_changed)
	EventBus.score_changed.connect(_on_score_changed)
	_on_score_changed(Wallet.score)

func bind_player(player: Node) -> void:
	_last_max_hp = player.max_hp
	_update_hp(player.hp, false)

func _on_player_hp_changed(_amount: int, new_hp: int) -> void:
	_update_hp(new_hp, true)

func _update_hp(hp: int, animate: bool) -> void:
	hp_label.text = "%d / %d" % [hp, _last_max_hp]
	var ratio := 0.0
	if _last_max_hp > 0:
		ratio = clampf(float(hp) / float(_last_max_hp), 0.0, 1.0)
	var target_width := HP_BAR_WIDTH * ratio
	var color := _hp_color(ratio)
	if _hp_tween and _hp_tween.is_valid():
		_hp_tween.kill()
	if not animate:
		hp_fill.size.x = target_width
		hp_fill.color = color
		return
	_hp_tween = create_tween()
	_hp_tween.set_parallel(true)
	var slide := _hp_tween.tween_property(hp_fill, "size:x", target_width, HP_TWEEN_TIME)
	slide.set_trans(Tween.TRANS_CUBIC)
	slide.set_ease(Tween.EASE_OUT)
	_hp_tween.tween_property(hp_fill, "color", color, HP_TWEEN_TIME)

func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return HP_FULL_COLOR.lerp(HP_WARN_COLOR, (1.0 - ratio) * 2.0)
	return HP_WARN_COLOR.lerp(HP_LOW_COLOR, 1.0 - ratio * 2.0)

func _on_round_state_changed(_new_state: int, _old_state: int) -> void:
	round_label.text = "Round %d" % RoundManager.current_round

func _on_score_changed(new_score: int) -> void:
	score_label.text = "%d" % new_score
