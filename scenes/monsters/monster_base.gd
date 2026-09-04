class_name MonsterBase
extends Node2D

const SCORE_ORB_SCENE: PackedScene = preload("res://scenes/orbs/score_orb.tscn")
const RANGED_PROJECTILE_SCENE: PackedScene = preload("res://scenes/monsters/ranged_projectile.tscn")

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
	if stats and randf() < stats.score_orb_drop_chance:
		_spawn_score_orb()
	EventBus.monster_died.emit(self, grid_pos)
	queue_free()

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
	if stats.is_ranged:
		player.take_damage(stats.attack_power)
		_fire_ranged_visual(player)
	elif is_at_front_row():
		player.take_damage(stats.attack_power)

func _fire_ranged_visual(player: Node) -> void:
	var proj: RangedProjectile = RANGED_PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.launch(global_position, player.global_position)
