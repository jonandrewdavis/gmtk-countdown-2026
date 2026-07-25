extends Node3D

const CELL = preload("uid://cau0iddxgec2w")

@export var Map: PackedScene
const BALL = preload("uid://c1yny3sauy8yu")
const GHOST = preload("uid://vydo5ihqeu0v")

@onready var navigation_region_3d: NavigationRegion3D = %NavigationRegion3D
@onready var player: Player = %Player
@onready var audio_stream_player_music: AudioStreamPlayer = %AudioStreamPlayerMusic

var cells = []

func _ready() -> void:
	# makes loading screens not grey like in editor.
	if not OS.is_debug_build():
		RenderingServer.set_default_clear_color(Color.BLACK)
		
		
	if OS.is_debug_build():
		print('DEBUG: Mute music while testing')
		audio_stream_player_music.volume_db = -50.0
		

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
	
	player.fade_in()

	_spawn_enemies()

	var secret_ball: RigidBody3D = BALL.instantiate()
	secret_ball.position = Vector3(100.0, 100.0, 100.0)
	add_child.call_deferred(secret_ball)
	secret_ball.freeze = true

# TODO: More flexible logic
func _spawn_enemies():
	var spawn_cells = cells.duplicate()
	spawn_cells.shuffle()

	for cell in spawn_cells:
		if get_tree().get_nodes_in_group("Enemies").size() >= 3:
			break
		if cell.global_transform.origin.distance_to(player.global_transform.origin) < 3.0 * Global.GRID_SIZE:
			continue
		var ghost = GHOST.instantiate()
		add_child(ghost)
		ghost.global_transform.origin = cell.global_transform.origin + Vector3(0.0, 1.0, 0.0)	
