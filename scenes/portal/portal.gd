extends Node2D

const APPEAR_TIME := 0.28
const HIDE_TIME := 0.18
const LINK_ALPHA := 0.22

@onready var entry: Node2D = $Entry
@onready var exit: Node2D = $Exit
@onready var link: Line2D = $Link

func _ready() -> void:
	# 位置直接跟著 ItemManager 的常數走，不會和子彈實際傳送點對不上
	entry.position = ItemManager.PORTAL_ENTRY
	exit.position = ItemManager.PORTAL_EXIT
	entry.trigger_radius = Bullet.PORTAL_TRIGGER_RADIUS
	exit.trigger_radius = Bullet.PORTAL_TRIGGER_RADIUS
	link.points = [ItemManager.PORTAL_ENTRY, ItemManager.PORTAL_EXIT]
	visible = false
	_set_rings_processing(false)
	EventBus.active_modifier_changed.connect(_on_active_modifier_changed)

func _on_active_modifier_changed(item: Resource) -> void:
	var active: bool = item is ItemData and item.id == &"portal"
	if active == visible:
		return
	if active:
		_appear()
	else:
		_vanish()

func _appear() -> void:
	visible = true
	_set_rings_processing(true)
	entry.appear_scale = 0.4
	exit.appear_scale = 0.4
	entry.modulate.a = 0.0
	exit.modulate.a = 0.0
	link.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	for ring in [entry, exit]:
		var grow := tween.tween_property(ring, "appear_scale", 1.0, APPEAR_TIME)
		grow.set_trans(Tween.TRANS_BACK)
		grow.set_ease(Tween.EASE_OUT)
		tween.tween_property(ring, "modulate:a", 1.0, APPEAR_TIME * 0.6)
	tween.tween_property(link, "modulate:a", LINK_ALPHA, APPEAR_TIME)

func _vanish() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for ring in [entry, exit]:
		tween.tween_property(ring, "appear_scale", 0.4, HIDE_TIME)
		tween.tween_property(ring, "modulate:a", 0.0, HIDE_TIME)
	tween.tween_property(link, "modulate:a", 0.0, HIDE_TIME)
	tween.chain().tween_callback(_on_vanished)

func _on_vanished() -> void:
	visible = false
	_set_rings_processing(false)

func _set_rings_processing(enabled: bool) -> void:
	entry.set_process(enabled)
	exit.set_process(enabled)
