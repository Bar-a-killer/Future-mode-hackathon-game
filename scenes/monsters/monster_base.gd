class_name MonsterBase
extends Node2D

@export var stats: MonsterStats
@export var half_size: Vector2 = Vector2(46, 46)

var current_hp: int
var grid_pos: Vector2i

func _ready() -> void:
	add_to_group("monsters")
	if stats:
		current_hp = stats.max_hp

func take_damage(amount: int) -> void:
	var final_amount := amount
	if stats and stats.frontal_damage_reduction > 0.0:
		final_amount = int(final_amount * (1.0 - stats.frontal_damage_reduction))
	current_hp -= final_amount
	if current_hp <= 0:
		die()

func die() -> void:
	GridManager.vacate(grid_pos)
	EventBus.monster_died.emit(self, grid_pos)
	queue_free()

func is_at_front_row() -> bool:
	return grid_pos.y >= GridManager.GRID_ROWS - 1

func advance() -> void:
	if is_at_front_row():
		return
	var new_pos := Vector2i(grid_pos.x, grid_pos.y + 1)
	if GridManager.is_occupied(new_pos):
		return
	GridManager.vacate(grid_pos)
	grid_pos = new_pos
	GridManager.occupy(grid_pos, self)
	position = GridManager.cell_to_world(grid_pos)

func execute_attack(player: Node) -> void:
	if not stats:
		return
	if stats.is_ranged or is_at_front_row():
		player.take_damage(stats.attack_power)
