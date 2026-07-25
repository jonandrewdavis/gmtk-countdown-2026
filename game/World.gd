extends Node3D

const CELL = preload("uid://cau0iddxgec2w")

@export var Map: PackedScene
const BALL = preload("uid://c1yny3sauy8yu")
const GHOST = preload("uid://vydo5ihqeu0v")

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
	
	#var ghost = GHOST.instantiate()
	#add_child(ghost)
	#ghost.global_transform.origin = cells.pick_random().global_transform.origin + Vector3(0.0, 1.0, 0.0)

	var secret_ball: RigidBody3D = BALL.instantiate()
	secret_ball.position = Vector3(100.0, 100.0, 100.0)
	add_child.call_deferred(secret_ball)
	secret_ball.freeze = true
