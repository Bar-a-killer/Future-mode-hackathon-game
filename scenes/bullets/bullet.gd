class_name Bullet
extends Node2D

const MAX_LIFETIME := 4.0
const BASE_RADIUS := 8.0
const SKIN := 0.5
const PORTAL_TRIGGER_RADIUS := 20.0
const WAVE_AMPLITUDE := 40.0
const WAVE_FREQUENCY := 6.0

var direction: Vector2 = Vector2.UP
var speed: float = 600.0
var damage: int = 5
var element: StringName = &""
var size_scale: float = 1.0
var wave_enabled: bool = false
var portal_enabled: bool = false

var _age: float = 0.0
var _wave_phase: float = 0.0

func _ready() -> void:
	scale = Vector2(size_scale, size_scale)

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= MAX_LIFETIME:
		queue_free()
		return
	if portal_enabled and global_position.distance_to(ItemManager.PORTAL_ENTRY) <= PORTAL_TRIGGER_RADIUS:
		global_position = ItemManager.PORTAL_EXIT
		return
	var from := global_position
	var to := from + _compute_step_vector(delta)
	var radius := BASE_RADIUS * size_scale
	var colliders := get_tree().get_nodes_in_group("monsters") + get_tree().get_nodes_in_group("walls") + get_tree().get_nodes_in_group("orbs")
	var hit := CollisionUtils.find_closest_hit(from, to, colliders, radius)
	if not hit.is_empty():
		var normal: Vector2 = hit["normal"]
		global_position = hit["point"] + normal * SKIN
		var target = hit["target"]
		if target is MonsterBase:
			target.take_damage(damage, element)
			EventBus.bullet_hit_monster.emit(self, target)
		elif target is ScoreOrb:
			target.collect()
		direction = direction.bounce(normal).normalized()
		_age = 0.0
	else:
		global_position = to
		if not get_viewport_rect().grow(60).has_point(global_position):
			queue_free()

func _compute_step_vector(delta: float) -> Vector2:
	var step := direction * speed
	if wave_enabled:
		_wave_phase += WAVE_FREQUENCY * delta
		var perpendicular := direction.orthogonal()
		step += perpendicular * cos(_wave_phase) * WAVE_AMPLITUDE * WAVE_FREQUENCY
	return step * delta
