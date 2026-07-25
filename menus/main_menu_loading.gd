extends Node3D

const MENU_SCENE := "res://menus/main_menu_temp.tscn"

@export var scenes_to_instantiate: Array[PackedScene] = []
@onready var target: Marker3D = %Target
@onready var progress_bar: TextureProgressBar = %ProgressBar

func _ready() -> void:
	# Muted while warming in case any scene plays sound on spawn.
	AudioServer.set_bus_mute(0, true)

	progress_bar.max_value = scenes_to_instantiate.size() + 1
	progress_bar.value = 0

	for scene in scenes_to_instantiate:
		await prepare_scene(scene)
		progress_bar.value += 1

	await get_tree().process_frame
	progress_bar.value = progress_bar.max_value

	AudioServer.set_bus_mute(0, false)
	get_tree().change_scene_to_file(MENU_SCENE)

func prepare_scene(scene: PackedScene) -> void:
	var instance = scene.instantiate()
	if instance is RigidBody3D:
		instance.freeze = true
	target.add_child(instance)
	await get_tree().create_timer(0.3).timeout
	instance.queue_free()
