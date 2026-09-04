extends Node

const GRID_COLS := 7
const GRID_ROWS := 9
const CELL_SIZE := Vector2(90, 90)
const GRID_ORIGIN := Vector2(45, 90)

const LANE_POSITIONS: Array[Vector2] = [
	Vector2(90, 1000),
	Vector2(225, 1000),
	Vector2(360, 1000),
	Vector2(495, 1000),
	Vector2(630, 1000),
]

var _occupancy: Dictionary = {}

func cell_to_world(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell.x * CELL_SIZE.x, cell.y * CELL_SIZE.y) + CELL_SIZE * 0.5

func world_to_cell(pos: Vector2) -> Vector2i:
	var local := pos - GRID_ORIGIN
	return Vector2i(int(local.x / CELL_SIZE.x), int(local.y / CELL_SIZE.y))

func is_occupied(cell: Vector2i) -> bool:
	return _occupancy.has(cell)

func occupy(cell: Vector2i, node: Node) -> void:
	_occupancy[cell] = node

func vacate(cell: Vector2i) -> void:
	_occupancy.erase(cell)

func get_wave_spawn_cells(count: int, row: int = 1) -> Array[Vector2i]:
	var cols: Array = range(GRID_COLS)
	cols.shuffle()
	var chosen: Array = cols.slice(0, count)
	chosen.sort()
	var cells: Array[Vector2i] = []
	for c in chosen:
		cells.append(Vector2i(c, row))
	return cells

func reset() -> void:
	_occupancy.clear()
