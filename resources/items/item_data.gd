class_name ItemData
extends Resource

enum EffectType { INSTANT, DURATION_BUFF, BULLET_MODIFIER }

@export var id: StringName
@export var display_name: String = ""
@export var effect_type: EffectType = EffectType.INSTANT
@export var description: String = ""
@export var icon: Texture2D
# 素材四周留白很多，記下實際有畫面的區域，顯示時才不會縮成一小點
@export var icon_region: Rect2 = Rect2()

# 沒有 region 就整張用，有 region 就裁成貼齊圖案的 AtlasTexture
func make_icon_texture() -> Texture2D:
	if icon == null:
		return null
	if icon_region.size.x <= 0.0 or icon_region.size.y <= 0.0:
		return icon
	var atlas := AtlasTexture.new()
	atlas.atlas = icon
	atlas.region = icon_region
	return atlas
