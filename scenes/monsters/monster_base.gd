class_name MonsterBase
extends Node2D

const SCORE_ORB_SCENE: PackedScene = preload("res://scenes/orbs/score_orb.tscn")
const RANGED_PROJECTILE_SCENE: PackedScene = preload("res://scenes/monsters/ranged_projectile.tscn")

const FIRE_TICK_DAMAGE := 2
const FIRE_DURATION := 2
const FREEZE_DURATION := 1
const MIN_HP_ALPHA := 0.3
const HIT_FLASH_TIME := 0.12
const HIT_PUNCH_SCALE := 1.08
const DEATH_POP_TIME := 0.18
const DEATH_POP_SCALE := 1.6
const FLASH_COLOR := Color(3.0, 3.0, 3.0, 1.0)
const STATUS_TINTS := {
	&"fire": Color(1.35, 0.7, 0.42),
	&"freeze": Color(0.5, 0.82, 1.35),
}

@export var stats: MonsterStats
@export var half_size: Vector2 = Vector2(46, 46)

var current_hp: int
var grid_pos: Vector2i
var is_boss: bool = false

var _status: Dictionary = {}
var _dying: bool = false
var _hit_tween: Tween
var _visual_base_scale: Vector2 = Vector2.ONE

@onready var _visual: Sprite2D = $Visual
@onready var _status_overlay: Node2D = $StatusOverlay

func _ready() -> void:
	add_to_group("monsters")
	if stats:
		current_hp = stats.max_hp
	_visual_base_scale = _visual.scale
	_status_overlay.setup(_visual_extent())
	_refresh_visual()

# 不同體型的怪物 Visual 多邊形大小不同，狀態特效要跟著寬高走
func _visual_extent() -> Vector2:
	if not _visual or not _visual.texture:
		return Vector2(35.0, 35.0)
	return _visual.texture.get_size() * 0.5 * _visual.scale

func has_status(status_name: StringName) -> bool:
	return _status.has(status_name)

func apply_status(status_name: StringName) -> void:
	if status_name == &"fire":
		_status.erase(&"freeze")
		_status[&"fire"] = FIRE_DURATION
	elif status_name == &"freeze":
		_status.erase(&"fire")
		_status[&"freeze"] = FREEZE_DURATION
	_refresh_visual()
	EventBus.status_applied.emit(self, status_name)

func tick_status() -> void:
	if _status.has(&"fire"):
		take_damage(FIRE_TICK_DAMAGE)
		if current_hp <= 0:
			return
	for key in _status.keys().duplicate():
		_status[key] -= 1
		if _status[key] <= 0:
			_status.erase(key)
			_refresh_visual()
			EventBus.status_expired.emit(self, key)

func take_damage(amount: int, element: StringName = &"") -> void:
	if _dying:
		return
	var final_amount := amount
	if element != &"" and has_status(_opposite_element(element)):
		final_amount *= 2
	if stats and stats.frontal_damage_reduction > 0.0:
		final_amount = int(final_amount * (1.0 - stats.frontal_damage_reduction))
	current_hp -= final_amount
	_refresh_visual()
	if element != &"":
		apply_status(element)
	if current_hp <= 0:
		die()
		return
	_play_hit_feedback()

# 色調 = 狀態色，透明度 = 血量，兩者合成同一個 modulate
func _refresh_visual() -> void:
	if not _visual:
		return
	_visual.modulate = _rest_modulate()
	if _status_overlay:
		_status_overlay.set_status(current_status_name())

func _rest_modulate() -> Color:
	var tint: Color = STATUS_TINTS.get(current_status_name(), Color(1.0, 1.0, 1.0))
	tint.a = _hp_alpha()
	return tint

func _hp_alpha() -> float:
	if not stats or stats.max_hp <= 0:
		return 1.0
	var ratio := clampf(float(current_hp) / float(stats.max_hp), 0.0, 1.0)
	return lerpf(MIN_HP_ALPHA, 1.0, ratio)

func current_status_name() -> StringName:
	if _status.has(&"fire"):
		return &"fire"
	if _status.has(&"freeze"):
		return &"freeze"
	return &""

func _opposite_element(element: StringName) -> StringName:
	return &"freeze" if element == &"fire" else &"fire"

func die() -> void:
	if _dying:
		return
	_dying = true
	GridManager.vacate(grid_pos)
	if stats and randf() < stats.score_orb_drop_chance:
		_spawn_score_orb()
	EventBus.monster_died.emit(self, grid_pos)
	if is_boss:
		EventBus.boss_defeated.emit()
	# 先退出群組，讓子彈跟回合邏輯立刻當它不存在，再播完死亡動畫
	remove_from_group("monsters")
	if _status_overlay:
		_status_overlay.set_status(&"")
	_play_death_pop()

# 受擊：瞬間漂白 + 放大，再彈回目前血量對應的透明度
func _play_hit_feedback() -> void:
	if not _visual:
		return
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	var rest := _rest_modulate()
	_visual.modulate = Color(FLASH_COLOR.r, FLASH_COLOR.g, FLASH_COLOR.b, rest.a)
	_visual.scale = _visual_base_scale * HIT_PUNCH_SCALE
	_hit_tween = create_tween()
	_hit_tween.set_parallel(true)
	_hit_tween.tween_property(_visual, "modulate", rest, HIT_FLASH_TIME)
	var punch := _hit_tween.tween_property(_visual, "scale", _visual_base_scale, HIT_FLASH_TIME)
	punch.set_trans(Tween.TRANS_BACK)
	punch.set_ease(Tween.EASE_OUT)

func _play_death_pop() -> void:
	if not _visual:
		queue_free()
		return
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	var tween := create_tween()
	tween.set_parallel(true)
	var pop := tween.tween_property(_visual, "scale", _visual_base_scale * DEATH_POP_SCALE, DEATH_POP_TIME)
	pop.set_trans(Tween.TRANS_QUAD)
	pop.set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "modulate", Color(FLASH_COLOR.r, FLASH_COLOR.g, FLASH_COLOR.b, 0.0), DEATH_POP_TIME)
	tween.chain().tween_callback(queue_free)

func _spawn_score_orb() -> void:
	var orb: ScoreOrb = SCORE_ORB_SCENE.instantiate()
	orb.grid_pos = grid_pos
	orb.value = stats.score_orb_value
	orb.position = GridManager.cell_to_world(grid_pos)
	get_tree().current_scene.add_child(orb)
	GridManager.occupy(grid_pos, orb)

func is_at_front_row() -> bool:
	return grid_pos.y >= GridManager.GRID_ROWS - 1

func advance() -> void:
	if is_boss:
		return
	if has_status(&"freeze"):
		return
	if is_at_front_row():
		return
	var new_pos := Vector2i(grid_pos.x, grid_pos.y + 1)
	if GridManager.is_occupied(new_pos):
		return
	GridManager.vacate(grid_pos)
	grid_pos = new_pos
	GridManager.occupy(grid_pos, self)
	position = GridManager.cell_to_world(grid_pos)

func retreat() -> void:
	if grid_pos.y <= 0:
		return
	var new_pos := Vector2i(grid_pos.x, grid_pos.y - 1)
	if GridManager.is_occupied(new_pos):
		return
	GridManager.vacate(grid_pos)
	grid_pos = new_pos
	GridManager.occupy(grid_pos, self)
	position = GridManager.cell_to_world(grid_pos)

func execute_attack(player: Node) -> void:
	if not stats or has_status(&"freeze"):
		return
	if stats.is_ranged:
		player.take_damage(stats.attack_power)
		_fire_ranged_visual(player)
	elif is_at_front_row():
		player.take_damage(stats.attack_power)

func _fire_ranged_visual(player: Node) -> void:
	var proj: RangedProjectile = RANGED_PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.launch(global_position, player.global_position)
