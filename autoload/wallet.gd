extends Node

var score: int = 0
var score_multiplier: float = 1.0

func add_score(amount: int) -> void:
	score += int(amount * score_multiplier)
	EventBus.score_changed.emit(score)

func apply_score_multiplier(mult: float) -> void:
	score_multiplier = mult
	EventBus.score_changed.emit(score)

func clear_score_multiplier() -> void:
	score_multiplier = 1.0

func on_death() -> void:
	score = 0
	EventBus.score_changed.emit(score)

func reset() -> void:
	score = 0
	score_multiplier = 1.0
	EventBus.score_changed.emit(score)
