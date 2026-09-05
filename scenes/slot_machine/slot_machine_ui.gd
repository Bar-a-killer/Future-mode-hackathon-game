extends CanvasLayer

const CELL_WIDTH := 168.0
const CELL_HEIGHT := 236.0
const ICON_BOX := Vector2(120.0, 118.0)
const SPIN_CELL_COUNT := 18
const SPIN_TIME := 1.15
const REEL_STAGGER := 0.22
const SNAP_OVERSHOOT := 26.0
const SNAP_TIME := 0.16
const LAND_TIME := 0.18
const PICK_TIME := 0.3
const LEVER_PULL_ANGLE := 0.62
const TEXT_COLOR := Color(0.18, 0.12, 0.1)
const SPINNING_TITLE := "轉動中…"
const READY_TITLE := "選擇一個技能"
const READY_HINT := "把游標移到轉輪上看說明"

@onready var panel: Control = $Panel
@onready var background: ColorRect = $Panel/Background
@onready var cabinet: Panel = $Panel/Cabinet
@onready var lever: Control = $Panel/Lever
@onready var lever_base: Panel = $Panel/LeverBase
@onready var title: Label = $Panel/Cabinet/Title
@onready var desc: Label = $Panel/Cabinet/Desc
@onready var buttons: Array[Button] = [
	$Panel/Cabinet/Window/Reel1,
	$Panel/Cabinet/Window/Reel2,
	$Panel/Cabinet/Window/Reel3,
]

var _choices: Array[ItemData] = []
var _busy: bool = false

func _ready() -> void:
	panel.visible = false
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_button_pressed.bind(i))
		buttons[i].mouse_entered.connect(_on_button_hovered.bind(i))
		buttons[i].pivot_offset = Vector2(CELL_WIDTH, CELL_HEIGHT) * 0.5

func show_choices(choices: Array[ItemData]) -> void:
	_choices = choices
	_busy = true
	panel.visible = true
	panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	title.text = SPINNING_TITLE
	desc.text = ""
	_play_open_animation()
	_play_lever_pull()
	for i in range(buttons.size()):
		buttons[i].disabled = true
		buttons[i].modulate = Color(1.0, 1.0, 1.0, 1.0)
		buttons[i].scale = Vector2.ONE
		_build_reel(i, choices[i])
		_spin_reel(i)

func _play_open_animation() -> void:
	background.modulate.a = 0.0
	cabinet.pivot_offset = cabinet.size * 0.5
	cabinet.scale = Vector2(0.86, 0.86)
	lever.modulate.a = 0.0
	lever_base.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(background, "modulate:a", 1.0, 0.18)
	tween.tween_property(lever, "modulate:a", 1.0, 0.24)
	tween.tween_property(lever_base, "modulate:a", 1.0, 0.24)
	var pop := tween.tween_property(cabinet, "scale", Vector2.ONE, 0.34)
	pop.set_trans(Tween.TRANS_BACK)
	pop.set_ease(Tween.EASE_OUT)

# 拉桿往下扳再彈回來，帶出「這一把是我拉的」的感覺
func _play_lever_pull() -> void:
	lever.rotation = 0.0
	var tween := create_tween()
	var pull := tween.tween_property(lever, "rotation", LEVER_PULL_ANGLE, 0.14)
	pull.set_trans(Tween.TRANS_QUAD)
	pull.set_ease(Tween.EASE_IN)
	var back := tween.tween_property(lever, "rotation", 0.0, 0.5)
	back.set_trans(Tween.TRANS_ELASTIC)
	back.set_ease(Tween.EASE_OUT)

# 把整條轉輪填成「一堆隨機道具 + 最後一格是真正抽中的道具」
func _build_reel(index: int, final_item: ItemData) -> void:
	var strip := _get_strip(index)
	for child in strip.get_children():
		strip.remove_child(child)
		child.queue_free()
	var pool: Array[ItemData] = ItemManager.ITEM_POOL
	for cell_index in range(SPIN_CELL_COUNT):
		strip.add_child(_make_cell(pool[randi() % pool.size()], cell_index))
	strip.add_child(_make_cell(final_item, SPIN_CELL_COUNT))
	strip.position.y = 0.0

# 一格 = 一個圖示 + 名稱；沒有素材的道具就把名稱放大置中
func _make_cell(item: ItemData, cell_index: int) -> Control:
	var cell := Control.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.position = Vector2(0.0, cell_index * CELL_HEIGHT)
	cell.size = Vector2(CELL_WIDTH, CELL_HEIGHT)

	var icon_texture := item.make_icon_texture()
	var name_label := Label.new()
	name_label.text = item.display_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", TEXT_COLOR)

	if icon_texture:
		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2((CELL_WIDTH - ICON_BOX.x) * 0.5, 20.0)
		icon.size = ICON_BOX
		cell.add_child(icon)
		name_label.position = Vector2(6.0, 150.0)
		name_label.size = Vector2(CELL_WIDTH - 12.0, 74.0)
		name_label.add_theme_font_size_override("font_size", 22)
	else:
		name_label.position = Vector2(6.0, 40.0)
		name_label.size = Vector2(CELL_WIDTH - 12.0, CELL_HEIGHT - 80.0)
		name_label.add_theme_font_size_override("font_size", 28)
	cell.add_child(name_label)
	return cell

# 三個轉輪錯開起停，最後一格會先衝過頭一點再彈回來卡住
func _spin_reel(index: int) -> void:
	var strip := _get_strip(index)
	var target_y := -SPIN_CELL_COUNT * CELL_HEIGHT
	var tween := create_tween()
	tween.tween_interval(index * REEL_STAGGER)
	var roll := tween.tween_property(strip, "position:y", target_y - SNAP_OVERSHOOT, SPIN_TIME)
	roll.set_trans(Tween.TRANS_CUBIC)
	roll.set_ease(Tween.EASE_OUT)
	var snap := tween.tween_property(strip, "position:y", target_y, SNAP_TIME)
	snap.set_trans(Tween.TRANS_BACK)
	snap.set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_reel_landed.bind(index))

func _on_reel_landed(index: int) -> void:
	var button := buttons[index]
	button.scale = Vector2(1.07, 0.93)
	var tween := create_tween()
	tween.set_parallel(true)
	var settle := tween.tween_property(button, "scale", Vector2.ONE, LAND_TIME)
	settle.set_trans(Tween.TRANS_BACK)
	settle.set_ease(Tween.EASE_OUT)
	var flash := tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), LAND_TIME)
	flash.from(Color(2.2, 2.2, 2.2, 1.0))
	if index == buttons.size() - 1:
		tween.chain().tween_callback(_enable_buttons)

func _enable_buttons() -> void:
	title.text = READY_TITLE
	desc.text = READY_HINT
	for button in buttons:
		button.disabled = false
	_busy = false

func _on_button_hovered(index: int) -> void:
	if _busy or index >= _choices.size():
		return
	desc.text = "%s — %s" % [_choices[index].display_name, _choices[index].description]

func _on_button_pressed(index: int) -> void:
	if _busy:
		return
	_busy = true
	for button in buttons:
		button.disabled = true
	var chosen := buttons[index]
	var tween := create_tween()
	tween.set_parallel(true)
	var punch := tween.tween_property(chosen, "scale", Vector2(1.12, 1.12), PICK_TIME * 0.4)
	punch.set_trans(Tween.TRANS_BACK)
	punch.set_ease(Tween.EASE_OUT)
	for i in range(buttons.size()):
		if i != index:
			tween.tween_property(buttons[i], "modulate:a", 0.25, PICK_TIME * 0.6)
	tween.chain().tween_property(panel, "modulate:a", 0.0, PICK_TIME * 0.5)
	tween.chain().tween_callback(_finish_selection.bind(index))

func _finish_selection(index: int) -> void:
	panel.visible = false
	panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	for button in buttons:
		button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		button.scale = Vector2.ONE
	_busy = false
	EventBus.item_selected.emit(_choices[index])

func _get_strip(index: int) -> Control:
	return buttons[index].get_node("Clip/Strip")
