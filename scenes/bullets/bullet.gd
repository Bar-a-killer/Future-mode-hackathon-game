class_name Bullet
extends Node2D

const MAX_LIFETIME := 4.0
const RADIUS := 8.0
const SKIN := 0.5

var direction: Vector2 = Vector2.UP
var speed: float = 600.0
var damage: int = 5

var _age: float = 0.0

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= MAX_LIFETIME:
		queue_free()
		return
	var from := global_position
	var to := from + direction * speed * delta
	var colliders := get_tree().get_nodes_in_group("monsters") + get_tree().get_nodes_in_group("walls") + get_tree().get_nodes_in_group("orbs")
	var hit := CollisionUtils.find_closest_hit(from, to, colliders, RADIUS)
	if not hit.is_empty():
		var normal: Vector2 = hit["normal"]
		global_position = hit["point"] + normal * SKIN
		var target = hit["target"]
		if target is MonsterBase:
			target.take_damage(damage)
			EventBus.bullet_hit_monster.emit(self, target)
		elif target is ScoreOrb:
			target.collect()
		direction = direction.bounce(normal).normalized()
		_age = 0.0
	else:
		global_position = to
		if not get_viewport_rect().grow(60).has_point(global_position):
			queue_free()
