extends Node3D

const CELL = preload("uid://cau0iddxgec2w")

@export var Map: PackedScene
const BALL = preload("uid://c1yny3sauy8yu")

@onready var navigation_region_3d: NavigationRegion3D = %NavigationRegion3D

var cells = []

func _ready() -> void:
	var map = Map.instantiate()
	var tile_map = map.get_tilemap()
	var used_tiles = tile_map.get_used_cells()
	map.free()
	for tile in used_tiles:
		var cell = CELL.instantiate()
		navigation_region_3d.add_child(cell)
		cells.append(cell)
		cell.global_transform.origin = Vector3(tile.x*Global.GRID_SIZE, 0, tile.y*Global.GRID_SIZE)
	for cell in cells:
		cell.update_faces(used_tiles)
	
	await get_tree().process_frame
	navigation_region_3d.bake_navigation_mesh.call_deferred()
	await navigation_region_3d.bake_finished
	
	add_child(BALL.instantiate())
