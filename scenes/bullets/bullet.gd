class_name Bullet
extends Node2D

const MAX_LIFETIME := 4.0
const BASE_RADIUS := 8.0
const SKIN := 0.5
const PORTAL_TRIGGER_RADIUS := 20.0
const WAVE_AMPLITUDE := 40.0
const WAVE_FREQUENCY := 6.0
const TRAIL_MAX_POINTS := 14
const TRAIL_WIDTH := 7.0

# 一眼認出這顆球帶什麼屬性：核心色 / 高光色 / 拖尾色
const ELEMENT_COLORS := {
	&"": {
		"core": Color(1.0, 0.85, 0.2),
		"glow": Color(1.0, 1.0, 0.9, 0.85),
		"trail": Color(1.0, 0.85, 0.2),
	},
	&"fire": {
		"core": Color(1.0, 0.38, 0.1),
		"glow": Color(1.0, 0.88, 0.5, 0.9),
		"trail": Color(1.0, 0.45, 0.12),
	},
	&"freeze": {
		"core": Color(0.35, 0.8, 1.0),
		"glow": Color(0.88, 0.98, 1.0, 0.9),
		"trail": Color(0.4, 0.85, 1.0),
	},
}

var direction: Vector2 = Vector2.UP
var speed: float = 600.0
var damage: int = 5
var element: StringName = &""
var size_scale: float = 1.0
var wave_enabled: bool = false
var portal_enabled: bool = false

var _age: float = 0.0
var _wave_phase: float = 0.0

@onready var _trail: Line2D = $Trail
@onready var _visual: Sprite2D = $Visual
@onready var _highlight: Sprite2D = $Highlight

func _ready() -> void:
	scale = Vector2(size_scale, size_scale)
	_trail.width = TRAIL_WIDTH * size_scale
	_trail.clear_points()
	_apply_element_colors()

func _apply_element_colors() -> void:
	var palette: Dictionary = ELEMENT_COLORS.get(element, ELEMENT_COLORS[&""])
	# 球體貼圖本身是白的，屬性色用 modulate 染上去
	_visual.modulate = palette["core"]
	_highlight.modulate = palette["glow"]
	var trail_color: Color = palette["trail"]
	_trail.default_color = trail_color
	# 渐層會蓋過 default_color，所以屬性色要重建一份
	var gradient := Gradient.new()
	gradient.set_color(0, Color(trail_color, 0.0))
	gradient.set_color(1, Color(trail_color, 0.6))
	_trail.gradient = gradient

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= MAX_LIFETIME:
		queue_free()
		return
	if portal_enabled and global_position.distance_to(ItemManager.PORTAL_ENTRY) <= PORTAL_TRIGGER_RADIUS:
		global_position = ItemManager.PORTAL_EXIT
		# 傳送不該在畫面上留下一條橫貫的殘影
		_trail.clear_points()
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
			return
	_push_trail_point(global_position)

func _push_trail_point(point: Vector2) -> void:
	_trail.add_point(point)
	while _trail.get_point_count() > TRAIL_MAX_POINTS:
		_trail.remove_point(0)

func _compute_step_vector(delta: float) -> Vector2:
	var step := direction * speed
	if wave_enabled:
		_wave_phase += WAVE_FREQUENCY * delta
		var perpendicular := direction.orthogonal()
		step += perpendicular * cos(_wave_phase) * WAVE_AMPLITUDE * WAVE_FREQUENCY
	return step * delta
