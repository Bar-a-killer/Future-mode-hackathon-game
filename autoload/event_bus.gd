extends Node

signal round_state_changed(new_state: int, old_state: int)
signal wave_spawn_requested(wave_index: int)
signal monster_spawned(monster: Node)
signal monster_died(monster: Node, grid_pos: Vector2i)
signal score_orb_dropped(grid_pos: Vector2i, value: int)
signal score_orb_collected(value: int)
signal player_fired(ball_count: int)
signal player_volley_resolved
signal bullet_hit_monster(bullet: Node, monster: Node)
signal bullet_hit_orb(bullet: Node, orb: Node)
signal player_damaged(amount: int, new_hp: int)
signal player_healed(amount: int, new_hp: int)
signal player_moved(new_lane_index: int)
signal player_died
signal game_over
signal score_changed(new_total: int)
signal slot_machine_triggered(round_index: int)
signal item_selected(item: Resource)
signal item_effect_applied(item: Resource)
signal active_modifier_changed(item: Resource)
signal status_applied(target: Node, status_name: StringName)
signal status_expired(target: Node, status_name: StringName)
signal boss_defeated
signal boss_warning
