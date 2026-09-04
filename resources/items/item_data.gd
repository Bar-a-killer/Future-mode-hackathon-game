class_name ItemData
extends Resource

enum EffectType { INSTANT, DURATION_BUFF, BULLET_MODIFIER }

@export var id: StringName
@export var display_name: String = ""
@export var effect_type: EffectType = EffectType.INSTANT
@export var description: String = ""
