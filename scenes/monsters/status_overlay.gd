extends Node2D

# 特效貼圖蓋過本體的比例，以及火焰要往上偏移多少（相對本體半高）
# 火焰畫在怪物後面、冰殼畫在前面且半透，才不會把怪物種類蓋掉
const ICE_COVER := 0.696
const FIRE_BACK_COVER := 1.14
const FIRE_FRONT_COVER := 0.63
const FIRE_Y_BIAS := -0.32
const ICE_ALPHA_MIN := 0.46
const ICE_ALPHA_RANGE := 0.16

@onready var _ice: Sprite2D = $Ice
@onready var _fire_a: Sprite2D = $FireA
@onready var _fire_b: Sprite2D = $FireB

var body_extent: Vector2 = Vector2(35.0, 35.0)

var _status: StringName = &""
var _time: float = 0.0
var _ice_base: Vector2 = Vector2.ONE
var _fire_a_base: Vector2 = Vector2.ONE
var _fire_b_base: Vector2 = Vector2.ONE

func _ready() -> void:
	set_process(false)
	visible = false

# 依怪物本體大小把貼圖縮放對齊，小怪大怪共用同一份素材
func setup(extent: Vector2) -> void:
	body_extent = extent
	var reach := maxf(extent.x, extent.y) * 2.0
	_ice_base = Vector2.ONE * (reach * ICE_COVER / float(_ice.texture.get_width()))
	# FireA 在本體後方燒得大一圈，FireB 在前方輕舆一層火舌
	_fire_a_base = Vector2.ONE * (reach * FIRE_BACK_COVER / float(_fire_a.texture.get_width()))
	_fire_b_base = Vector2.ONE * (reach * FIRE_FRONT_COVER / float(_fire_b.texture.get_width()))
	_ice.scale = _ice_base
	_fire_a.scale = _fire_a_base
	_fire_b.scale = _fire_b_base
	_fire_a.position = Vector2(0.0, extent.y * FIRE_Y_BIAS)
	_fire_b.position = Vector2(0.0, extent.y * 0.1)

func set_status(status_name: StringName) -> void:
	_status = status_name
	var active := status_name != &""
	visible = active
	set_process(active)
	_ice.visible = status_name == &"freeze"
	_fire_a.visible = status_name == &"fire"
	_fire_b.visible = status_name == &"fire"
	_time = 0.0
	if active:
		_animate(0.0)

func _process(delta: float) -> void:
	_time += delta
	_animate(delta)

func _animate(_delta: float) -> void:
	match _status:
		&"fire":
			_animate_fire()
		&"freeze":
			_animate_ice()

# 兩層火焰用不同頻率跳動，看起來才不像單張圖在閃
func _animate_fire() -> void:
	_fire_a.modulate.a = 0.78 + (sin(_time * 13.0) * 0.5 + 0.5) * 0.22
	_fire_b.modulate.a = 0.3 + (sin(_time * 9.0 + 2.1) * 0.5 + 0.5) * 0.25
	_fire_a.scale = _fire_a_base * Vector2(1.0 + sin(_time * 11.0) * 0.05, 1.0 + sin(_time * 8.0) * 0.09)
	_fire_b.scale = _fire_b_base * Vector2(1.0 - sin(_time * 9.5 + 1.0) * 0.06, 1.0 + sin(_time * 7.0 + 0.7) * 0.11)
	_fire_a.position.x = sin(_time * 5.0) * body_extent.x * 0.06
	_fire_b.position.x = sin(_time * 6.3 + 1.6) * body_extent.x * 0.09

func _animate_ice() -> void:
	_ice.modulate.a = ICE_ALPHA_MIN + (sin(_time * 2.2) * 0.5 + 0.5) * ICE_ALPHA_RANGE
	_ice.rotation = sin(_time * 0.9) * 0.035
	_ice.scale = _ice_base * (1.0 + sin(_time * 1.6) * 0.02)
