extends Node

enum State {
	WAVE_SPAWN,
	PLAYER_AIM,
	RESOLVE,
	MONSTER_ATTACK,
	MOVEMENT_CHECK,
	SLOT_MACHINE_CHECK,
	GAME_OVER_CHECK,
	GAME_OVER,
}

const MONSTER_SCENES: Array[PackedScene] = [
	preload("res://scenes/monsters/small_melee.tscn"),
	preload("res://scenes/monsters/small_melee.tscn"),
	preload("res://scenes/monsters/big_melee.tscn"),
	preload("res://scenes/monsters/big_melee_special.tscn"),
	preload("res://scenes/monsters/small_ranged_special.tscn"),
]
const MIN_WAVE_MONSTER_COUNT := 4
const MAX_WAVE_MONSTER_COUNT := 6
const WAVE_SPAWN_ROW := 1
const MONSTER_ATTACK_DELAY := 0.5
const POST_VOLLEY_DELAY := 0.5

var state: State = State.WAVE_SPAWN
var current_round: int = 1
var player: Node = null
var next_movement_round: int = 0

var _attack_timer: Timer
var _post_volley_timer: Timer

func _ready() -> void:
	_attack_timer = Timer.new()
	_attack_timer.one_shot = true
	_attack_timer.wait_time = MONSTER_ATTACK_DELAY
	add_child(_attack_timer)

	_post_volley_timer = Timer.new()
	_post_volley_timer.one_shot = true
	_post_volley_timer.wait_time = POST_VOLLEY_DELAY
	add_child(_post_volley_timer)
	_post_volley_timer.timeout.connect(_on_post_volley_timeout)

	EventBus.player_volley_resolved.connect(_on_volley_resolved)

func start(player_node: Node) -> void:
	player = player_node
	current_round = 1
	_roll_next_movement_round()
	GridManager.reset()
	Wallet.reset()
	_set_state(State.WAVE_SPAWN)

func _roll_next_movement_round() -> void:
	next_movement_round = current_round + randi_range(2, 4)

func _set_state(new_state: State) -> void:
	var old_state := state
	state = new_state
	EventBus.round_state_changed.emit(new_state, old_state)
	_enter_state(new_state)

func _enter_state(s: State) -> void:
	match s:
		State.WAVE_SPAWN:
			_enter_wave_spawn()
		State.PLAYER_AIM:
			_enter_player_aim()
		State.RESOLVE:
			_set_state(State.MONSTER_ATTACK)
		State.MONSTER_ATTACK:
			_enter_monster_attack()
		State.MOVEMENT_CHECK:
			_enter_movement_check()
		State.SLOT_MACHINE_CHECK:
			_set_state(State.GAME_OVER_CHECK)
		State.GAME_OVER_CHECK:
			_enter_game_over_check()
		State.GAME_OVER:
			Wallet.on_death()
			EventBus.game_over.emit()

func _enter_wave_spawn() -> void:
	EventBus.wave_spawn_requested.emit(current_round)
	var monster_count := randi_range(MIN_WAVE_MONSTER_COUNT, MAX_WAVE_MONSTER_COUNT)
	for cell in GridManager.get_wave_spawn_cells(monster_count, WAVE_SPAWN_ROW):
		var monster: MonsterBase = MONSTER_SCENES.pick_random().instantiate()
		monster.grid_pos = cell
		monster.position = GridManager.cell_to_world(cell)
		get_tree().current_scene.add_child(monster)
		GridManager.occupy(cell, monster)
		EventBus.monster_spawned.emit(monster)
	_set_state(State.PLAYER_AIM)

func _enter_player_aim() -> void:
	player.can_aim = true

func _on_volley_resolved() -> void:
	if state == State.PLAYER_AIM:
		player.can_aim = false
		_post_volley_timer.start()

func _on_post_volley_timeout() -> void:
	if state == State.PLAYER_AIM:
		_set_state(State.RESOLVE)

func _enter_monster_attack() -> void:
	_attack_timer.start()
	await _attack_timer.timeout
	if state != State.MONSTER_ATTACK:
		return
	var monsters := get_tree().get_nodes_in_group("monsters")
	monsters.sort_custom(func(a, b): return a.grid_pos.y > b.grid_pos.y)
	for monster in monsters:
		monster.advance()
	for monster in monsters:
		monster.execute_attack(player)
	_set_state(State.MOVEMENT_CHECK)

func _enter_movement_check() -> void:
	if current_round >= next_movement_round:
		var tween: Tween = player.move_to_random_lane()
		await tween.finished
		_roll_next_movement_round()
	_set_state(State.SLOT_MACHINE_CHECK)

func _enter_game_over_check() -> void:
	if player.hp <= 0:
		_set_state(State.GAME_OVER)
		return
	current_round += 1
	_set_state(State.WAVE_SPAWN)
