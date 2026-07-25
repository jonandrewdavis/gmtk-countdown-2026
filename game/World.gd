extends Node3D

const CELL = preload("uid://cau0iddxgec2w")

@export var Map: PackedScene
const BALL = preload("uid://c1yny3sauy8yu")
const GHOST = preload("uid://vydo5ihqeu0v")

@onready var navigation_region_3d: NavigationRegion3D = %NavigationRegion3D
@onready var player: Player = %Player

var cells = []

func _ready() -> void:
	Global.signal_enemy_target_changed.connect(_update_combat_music)
	SoundManager.crossfade_bgm(SoundManager.MUSIC_INTRO)

	_build_cells()
	await _bake_navigation()
	_spawn_enemies()
	player.fade_in()

func _update_combat_music() -> void:
	SoundManager.crossfade_bgm(SoundManager.MUSIC_COMBAT if _any_enemy_hunting() else SoundManager.MUSIC_INTRO)

func _any_enemy_hunting() -> bool:
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy.state in [Enemy.States.DYING, Enemy.States.DECAYING]:
			continue
		if is_instance_valid(enemy.target) and enemy.target.is_in_group("PlayerCharacter"):
			return true

	return false

func _build_cells() -> void:
	var map = Map.instantiate()
	var used_tiles = map.get_tilemap().get_used_cells()
	map.free()

	for tile in used_tiles:
		var cell = CELL.instantiate()
		navigation_region_3d.add_child(cell)
		cells.append(cell)
		cell.global_transform.origin = Vector3(tile.x * Global.GRID_SIZE, 0, tile.y * Global.GRID_SIZE)

	for cell in cells:
		cell.update_faces(used_tiles)

func _bake_navigation() -> void:
	await get_tree().process_frame
	navigation_region_3d.bake_navigation_mesh.call_deferred()
	await navigation_region_3d.bake_finished

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
