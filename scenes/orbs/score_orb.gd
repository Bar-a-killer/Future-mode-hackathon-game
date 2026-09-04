class_name ScoreOrb
extends Node2D

@export var half_size: Vector2 = Vector2(20, 20)

var value: int = 10
var grid_pos: Vector2i

func _ready() -> void:
	add_to_group("orbs")

func collect() -> void:
	GridManager.vacate(grid_pos)
	Wallet.add_score(value)
	EventBus.score_orb_collected.emit(value)
	queue_free()
