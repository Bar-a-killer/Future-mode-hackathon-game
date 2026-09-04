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
	var pool := ITEM_POOL.duplicate()
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
			EventBus.active_modifier_changed.emit(item)
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
			player.add_ball_count([1, 5, 10, 20].pick_random())
		&"instant_score":
			Wallet.add_score(INSTANT_SCORE_BASE_VALUE * 3)
		&"shockwave":
			var monsters := player.get_tree().get_nodes_in_group("monsters")
			monsters.sort_custom(func(a, b): return a.grid_pos.y < b.grid_pos.y)
			for m in monsters:
				m.retreat()

func build_bullet_params() -> Array[Dictionary]:
	var base := {
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
		var left := base.duplicate()
		left["angle_offset"] = -TRIPLE_SHOT_ANGLE_DEG
		var center := base.duplicate()
		var right := base.duplicate()
		right["angle_offset"] = TRIPLE_SHOT_ANGLE_DEG
		return [left, center, right]
	return [base]
