class_name Player
extends Node2D

const BULLET_SCENE: PackedScene = preload("res://scenes/bullets/bullet.tscn")
const BASE_BALL_COUNT := 10
const BASE_DAMAGE := 5
const BULLET_SPEED := 600.0
const FIRE_INTERVAL := 0.06
const MIN_DRAG_DISTANCE := 20.0
const AIM_LINE_LENGTH := 80.0

@export var max_hp: int = 100

var hp: int
var ball_count: int = BASE_BALL_COUNT
var can_aim: bool = false

var _dragging: bool = false
var _drag_start: Vector2
var _fire_direction: Vector2 = Vector2.UP
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
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_dragging = true
			_drag_start = touch_event.position
			aim_line.visible = true
			aim_line.points = [Vector2.ZERO, Vector2.ZERO]
		elif _dragging:
			_dragging = false
			aim_line.visible = false
			var drag_vector: Vector2 = touch_event.position - _drag_start
			if drag_vector.length() >= MIN_DRAG_DISTANCE:
				_start_volley(drag_vector.normalized())
	elif event is InputEventScreenDrag and _dragging:
		var drag_event := event as InputEventScreenDrag
		var drag_vector: Vector2 = drag_event.position - _drag_start
		var shown: Vector2 = drag_vector if drag_vector.length() < AIM_LINE_LENGTH else drag_vector.normalized() * AIM_LINE_LENGTH
		aim_line.points = [Vector2.ZERO, shown]

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
	_spawn_bullet(_fire_direction)
	_balls_to_fire -= 1
	if _balls_to_fire <= 0:
		_fire_timer.stop()

func _spawn_bullet(direction: Vector2) -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.direction = direction
	bullet.damage = BASE_DAMAGE
	bullet.speed = BULLET_SPEED
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
