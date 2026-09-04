class_name Bullet
extends Area2D

var direction: Vector2 = Vector2.UP
var speed: float = 600.0
var damage: int = 5

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if not get_viewport_rect().grow(60).has_point(global_position):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is MonsterBase:
		area.take_damage(damage)
		EventBus.bullet_hit_monster.emit(self, area)
		queue_free()

func _on_body_entered(_body: Node) -> void:
	queue_free()
