class_name RangedProjectile
extends Node2D

const TRAVEL_TIME := 0.3

func launch(from: Vector2, to: Vector2) -> void:
	global_position = from
	var tween := create_tween()
	tween.tween_property(self, "global_position", to, TRAVEL_TIME)
	tween.finished.connect(queue_free)
