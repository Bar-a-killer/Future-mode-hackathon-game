extends Node

const ITEM_POOL: Array[ItemData] = [
	preload("res://resources/items/data/item_portal.tres"),
	preload("res://resources/items/data/item_freeze_gun.tres"),
	preload("res://resources/items/data/item_triple_shot.tres"),
	preload("res://resources/items/data/item_fireball.tres"),
	preload("res://resources/items/data/item_wave_shot.tres"),
	preload("res://resources/items/data/item_shockwave.tres"),
	preload("res://resources/items/data/item_score_x2.tres"),
	preload("res://resources/items/data/item_random_heal.tres"),
	preload("res://resources/items/data/item_random_ball_boost.tres"),
	preload("res://resources/items/data/item_instant_score.tres"),
	preload("res://resources/items/data/item_enlarge_bullet.tres"),
]

const TRIPLE_SHOT_ANGLE_DEG := 15.0
const PORTAL_ENTRY := Vector2(360, 500)
const PORTAL_EXIT := Vector2(150, 150)
const INSTANT_SCORE_BASE_VALUE := 10

var current_active_modifier: ItemData = null

func pick_three_distinct() -> Array[ItemData]:
	var pool: Array[ItemData] = ITEM_POOL.duplicate()
	pool.shuffle()
	var chosen: Array[ItemData] = []
	for i in range(3):
		chosen.append(pool[i])
	return chosen

func apply_item(item: ItemData) -> void:
	_clear_current_modifier()
	match item.effect_type:
		ItemData.EffectType.INSTANT:
			_apply_instant(item.id)
		ItemData.EffectType.DURATION_BUFF, ItemData.EffectType.BULLET_MODIFIER:
			current_active_modifier = item
			if item.id == &"score_x2":
				Wallet.apply_score_multiplier(2.0)
	# 一律發一次（沒有修飾器時為 null），監聽者才知道上一個效果已經被退掉
	EventBus.active_modifier_changed.emit(current_active_modifier)
	EventBus.item_effect_applied.emit(item)

func _clear_current_modifier() -> void:
	if current_active_modifier and current_active_modifier.id == &"score_x2":
		Wallet.clear_score_multiplier()
	current_active_modifier = null

func _apply_instant(id: StringName) -> void:
	var player := RoundManager.player
	match id:
		&"random_heal":
			player.heal(randi_range(5, player.max_hp))
		&"random_ball_boost":
			var amounts: Array[int] = [1, 5, 10, 20]
			var chosen: int = amounts.pick_random()
			player.add_ball_count(chosen)
			_show_ball_boost_popup(player, chosen)
		&"instant_score":
			Wallet.add_score(INSTANT_SCORE_BASE_VALUE * 3)
		&"shockwave":
			var monsters: Array = player.get_tree().get_nodes_in_group("monsters")
			monsters.sort_custom(func(a, b): return a.grid_pos.y < b.grid_pos.y)
			for m in monsters:
				m.retreat()

func _show_ball_boost_popup(player: Node, amount: int) -> void:
	var images: Dictionary[int, String] = {
		1: "res://picture/加球1.PNG",
		5: "res://picture/加球5.png",
		10: "res://picture/加球10 PNG.png",
		20: "res://picture/加球20.png",
	}
	var regions: Dictionary[int, Rect2] = {
		1: Rect2(8, 32, 1304, 1280),
		5: Rect2(8, 4, 1316, 1320),
		10: Rect2(8, 4, 1312, 1312),
		20: Rect2(0, 4, 1320, 1316),
	}

	var texture: Texture2D = load(images[amount]) as Texture2D
	if not texture:
		return

	var popup := Node2D.new()
	var sprite := Sprite2D.new()
	sprite.centered = true
	sprite.scale = Vector2(0.06, 0.06)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = regions[amount]
	sprite.texture = atlas
	popup.add_child(sprite)
	popup.global_position = player.global_position + Vector2(0, -100)
	player.get_tree().current_scene.add_child(popup)

	var tween: Tween = popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "global_position:y", popup.global_position.y - 80, 0.6)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(popup.queue_free)

func build_bullet_params() -> Array[Dictionary]:
	var base: Dictionary = {
		"element": &"",
		"size_scale": 1.0,
		"wave_enabled": false,
		"portal_enabled": false,
		"angle_offset": 0.0,
	}
	if current_active_modifier:
		match current_active_modifier.id:
			&"freeze_gun":
				base["element"] = &"freeze"
			&"fireball":
				base["element"] = &"fire"
			&"enlarge_bullet":
				base["size_scale"] = 2.0
			&"wave_shot":
				base["wave_enabled"] = true
			&"portal":
				base["portal_enabled"] = true
	if current_active_modifier and current_active_modifier.id == &"triple_shot":
		var left: Dictionary = base.duplicate()
		left["angle_offset"] = -TRIPLE_SHOT_ANGLE_DEG
		var center: Dictionary = base.duplicate()
		var right: Dictionary = base.duplicate()
		right["angle_offset"] = TRIPLE_SHOT_ANGLE_DEG
		return [left, center, right]
	return [base]
