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

const MONSTER_SCENE: PackedScene = preload("res://scenes/monsters/small_melee.tscn")
const WAVE_MONSTER_COUNT := 6
const AIM_TIMEOUT := 8.0
const MONSTER_ATTACK_DELAY := 0.5

var state: State = State.WAVE_SPAWN
var current_round: int = 1
var player: Node = null

var _aim_timer: Timer
var _attack_timer: Timer

func _ready() -> void:
	_aim_timer = Timer.new()
	_aim_timer.one_shot = true
	_aim_timer.wait_time = AIM_TIMEOUT
	add_child(_aim_timer)
	_aim_timer.timeout.connect(_on_aim_timeout)

	_attack_timer = Timer.new()
	_attack_timer.one_shot = true
	_attack_timer.wait_time = MONSTER_ATTACK_DELAY
	add_child(_attack_timer)

	EventBus.player_volley_resolved.connect(_on_volley_resolved)

func start(player_node: Node) -> void:
	player = player_node
	current_round = 1
	GridManager.reset()
	_set_state(State.WAVE_SPAWN)

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
			_set_state(State.SLOT_MACHINE_CHECK)
		State.SLOT_MACHINE_CHECK:
			_set_state(State.GAME_OVER_CHECK)
		State.GAME_OVER_CHECK:
			_enter_game_over_check()
		State.GAME_OVER:
			EventBus.game_over.emit()

func _enter_wave_spawn() -> void:
	if get_tree().get_nodes_in_group("monsters").is_empty():
		EventBus.wave_spawn_requested.emit(current_round)
		for cell in GridManager.get_wave_spawn_cells(WAVE_MONSTER_COUNT):
			var monster: MonsterBase = MONSTER_SCENE.instantiate()
			monster.grid_pos = cell
			monster.position = GridManager.cell_to_world(cell)
			get_tree().current_scene.add_child(monster)
			GridManager.occupy(cell, monster)
			EventBus.monster_spawned.emit(monster)
	_set_state(State.PLAYER_AIM)

func _enter_player_aim() -> void:
	player.can_aim = true
	_aim_timer.start()

func _on_aim_timeout() -> void:
	if state == State.PLAYER_AIM:
		player.can_aim = false
		_set_state(State.RESOLVE)

func _on_volley_resolved() -> void:
	if state == State.PLAYER_AIM:
		_aim_timer.stop()
		player.can_aim = false
		_set_state(State.RESOLVE)

func _enter_monster_attack() -> void:
	_attack_timer.start()
	await _attack_timer.timeout
	if state != State.MONSTER_ATTACK:
		return
	for monster in get_tree().get_nodes_in_group("monsters"):
		monster.execute_attack(player)
	_set_state(State.MOVEMENT_CHECK)

func _enter_game_over_check() -> void:
	if player.hp <= 0:
		_set_state(State.GAME_OVER)
		return
	current_round += 1
	_set_state(State.WAVE_SPAWN)
