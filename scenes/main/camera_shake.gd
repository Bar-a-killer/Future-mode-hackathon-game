extends Camera2D

const TRAUMA_DECAY := 2.4
const MAX_OFFSET := Vector2(16.0, 12.0)
const PLAYER_HIT_TRAUMA := 0.8
const MONSTER_DEATH_TRAUMA := 0.35

var _trauma: float = 0.0

func _ready() -> void:
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.monster_died.connect(_on_monster_died)

func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(_trauma - TRAUMA_DECAY * delta, 0.0)
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	# 用 trauma 的平方讓震動尾巴收得更乾脆
	var amount := _trauma * _trauma
	offset = Vector2(randf_range(-1.0, 1.0) * MAX_OFFSET.x, randf_range(-1.0, 1.0) * MAX_OFFSET.y) * amount

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func _on_player_damaged(_amount: int, _new_hp: int) -> void:
	add_trauma(PLAYER_HIT_TRAUMA)

func _on_monster_died(_monster: Node, _grid_pos: Vector2i) -> void:
	add_trauma(MONSTER_DEATH_TRAUMA)
