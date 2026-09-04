class_name MonsterBase
extends Area2D

@export var stats: MonsterStats

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

func execute_attack(player: Node) -> void:
	if stats:
		player.take_damage(stats.attack_power)
