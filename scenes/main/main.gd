extends Node2D

@onready var player: Player = $Player
@onready var hud: CanvasLayer = $HUD
@onready var slot_machine_ui: CanvasLayer = $SlotMachineUI

func _ready() -> void:
	hud.bind_player(player)
	RoundManager.start(player, slot_machine_ui)
