class_name Player
extends Node2D

const BULLET_SCENE: PackedScene = preload("res://scenes/bullets/bullet.tscn")
const BASE_BALL_COUNT := 10
const BASE_DAMAGE := 5
const BULLET_SPEED := 600.0
const FIRE_INTERVAL := 0.06
const MIN_AIM_DISTANCE := 40.0
const MAX_AIM_ANGLE_DEG := 80.0
const MAX_AIM_RAY_LENGTH := 2000.0

@export var max_hp: int = 100

const LANE_MOVE_TIME := 0.4

var hp: int
var ball_count: int = BASE_BALL_COUNT
var can_aim: bool = false:
	set(value):
		can_aim = value
		if not value:
			_aim_ready = false
			if aim_line:
				aim_line.visible = false
var current_lane_index: int = 2

var _fire_direction: Vector2 = Vector2.UP
var _aim_ready: bool = false
var _balls_in_flight: int = 0
var _balls_to_fire: int = 0

@onready var muzzle: Marker2D = $Muzzle
@onready var aim_line: Line2D = $AimLine
@onready var _fire_timer: Timer = $FireTimer

func _ready() -> void:
	hp = max_hp
	aim_line.visible = false
	_fire_timer.wait_time = FIRE_INTERVAL
	_fire_timer.timeout.connect(_on_fire_timer_timeout)

func _input(event: InputEvent) -> void:
	if not can_aim:
		return
	if event is InputEventMouseMotion:
		_update_aim((event as InputEventMouseMotion).position)
	elif event is InputEventScreenDrag:
		_update_aim((event as InputEventScreenDrag).position)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		_update_aim(touch_event.position)
		if not touch_event.pressed and _aim_ready:
			_start_volley(_fire_direction)

# 以「滑鼠 / 觸控點相對角色的角度」決定瞄準方向
func _update_aim(screen_pos: Vector2) -> void:
	var offset: Vector2 = _screen_to_world(screen_pos) - global_position
	_aim_ready = offset.length() >= MIN_AIM_DISTANCE
	if not _aim_ready:
		aim_line.visible = false
		return
	_fire_direction = _clamp_aim_direction(offset.normalized())
	aim_line.visible = true
	_update_aim_line(_fire_direction)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

# 只允許往上半圈射擊,並限制最大偏角,避免貼地的無效平射
func _clamp_aim_direction(dir: Vector2) -> Vector2:
	var limit := deg_to_rad(MAX_AIM_ANGLE_DEG)
	var angle := clampf(Vector2.UP.angle_to(dir), -limit, limit)
	return Vector2.UP.rotated(angle)

func _update_aim_line(direction: Vector2) -> void:
	var from := muzzle.global_position
	var to := from + direction * MAX_AIM_RAY_LENGTH
	var colliders := get_tree().get_nodes_in_group("monsters") + get_tree().get_nodes_in_group("walls") + get_tree().get_nodes_in_group("orbs")
	var hit := CollisionUtils.find_closest_hit(from, to, colliders)
	var end_point: Vector2 = hit["point"] if not hit.is_empty() else to
	aim_line.points = [to_local(from), to_local(end_point)]

func _start_volley(direction: Vector2) -> void:
	can_aim = false
	_fire_direction = direction
	_balls_to_fire = ball_count
	_balls_in_flight = 0
	_fire_timer.start()

func _on_fire_timer_timeout() -> void:
	if _balls_to_fire <= 0:
		_fire_timer.stop()
		return
	for params in ItemManager.build_bullet_params():
		_spawn_bullet(_fire_direction, params)
	_balls_to_fire -= 1
	if _balls_to_fire <= 0:
		_fire_timer.stop()

func _spawn_bullet(direction: Vector2, params: Dictionary) -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()
	var angle_offset: float = params.get("angle_offset", 0.0)
	bullet.global_position = muzzle.global_position
	bullet.direction = direction.rotated(deg_to_rad(angle_offset))
	bullet.damage = BASE_DAMAGE
	bullet.speed = BULLET_SPEED
	bullet.element = params.get("element", &"")
	bullet.size_scale = params.get("size_scale", 1.0)
	bullet.wave_enabled = params.get("wave_enabled", false)
	bullet.portal_enabled = params.get("portal_enabled", false)
	get_tree().current_scene.add_child(bullet)
	_balls_in_flight += 1
	bullet.tree_exiting.connect(_on_bullet_resolved, CONNECT_ONE_SHOT)
	EventBus.player_fired.emit(ball_count)

func _on_bullet_resolved() -> void:
	_balls_in_flight -= 1
	if _balls_in_flight <= 0 and _balls_to_fire <= 0:
		EventBus.player_volley_resolved.emit()

func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	EventBus.player_damaged.emit(amount, hp)

func heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)
	EventBus.player_healed.emit(amount, hp)

func add_ball_count(amount: int) -> void:
	ball_count += amount

func move_to_random_lane() -> Tween:
	var positions := GridManager.LANE_POSITIONS
	var choices: Array[int] = []
	for i in range(positions.size()):
		if i != current_lane_index:
			choices.append(i)
	var new_index: int = choices.pick_random()
	current_lane_index = new_index
	var tween := create_tween()
	tween.tween_property(self, "global_position", positions[new_index], LANE_MOVE_TIME)
	tween.finished.connect(func(): EventBus.player_moved.emit(new_index))
	return tween
