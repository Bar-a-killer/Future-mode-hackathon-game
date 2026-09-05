extends Node2D

@export var ring_color: Color = Color(0.35, 0.85, 1.0)
@export var trigger_radius: float = 20.0
@export var halo_radius: float = 34.0
@export var spin_speed: float = 2.2

# 由 portal.gd 用 Tween 推動的出現/收起縮放，和 _process 的呼吸脈動相乘
var appear_scale: float = 1.0

var _phase: float = 0.0

func _process(delta: float) -> void:
	_phase += delta
	rotation = _phase * spin_speed
	var pulse := 1.0 + sin(_phase * 4.0) * 0.06
	scale = Vector2.ONE * pulse * appear_scale
	queue_redraw()

func _draw() -> void:
	# 外圈光暈
	draw_arc(Vector2.ZERO, halo_radius, 0.0, TAU, 48, Color(ring_color, 0.28), 3.0)
	# 實際會觸發傳送的半徑
	draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 40, Color(ring_color, 0.9), 3.0)
	# 三片旋轉葉片，讓它看得出來在轉
	var blade_radius := trigger_radius * 1.55
	for i in range(3):
		var start := TAU * float(i) / 3.0
		draw_arc(Vector2.ZERO, blade_radius, start, start + 0.85, 12, Color(ring_color, 0.75), 5.0)
	draw_circle(Vector2.ZERO, trigger_radius * 0.45, Color(ring_color, 0.35))
