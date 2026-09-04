class_name Wall
extends Node2D

@export var half_size: Vector2 = Vector2(10, 10)

func _ready() -> void:
	add_to_group("walls")
