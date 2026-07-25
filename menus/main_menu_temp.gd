extends CanvasLayer
@onready var button_start: Button = %ButtonStart
@onready var button_tutorial: Button = %ButtonTutorial
@onready var color_rect: ColorRect = %ColorRect
@onready var main_margin: MarginContainer = %MainMargin
@onready var preview_camera: Camera3D = $MainMenu/WorldMenuPreview/Camera3D
@onready var slider_volume: HSlider = %SliderVolume
@onready var how_to_play_modal: PanelContainer = %HowToPlayModal
@onready var button_return_to_menu: Button = %ButtonReturnToMenu

func _ready():
	how_to_play_modal.hide()
	button_start.pressed.connect(_start)
	button_tutorial.pressed.connect(func(): how_to_play_modal.show())
	button_return_to_menu.pressed.connect(func(): how_to_play_modal.hide())

	SoundManager.crossfade_bgm(SoundManager.MUSIC_TITLE)

	slider_volume.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM")))
	slider_volume.value_changed.connect(_on_volume_changed)

func _on_volume_changed(value: float) -> void:
	var volume_db := linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), volume_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), volume_db)

func _start():
	SoundManager.crossfade_bgm(null, 4.0)

	var text_tween = get_tree().create_tween()
	text_tween.tween_property(main_margin, 'modulate:a', 0.0, 0.4)
	
	var camera_tween = create_tween().set_trans(Tween.TRANS_SINE)
	camera_tween.tween_property(preview_camera, "fov", 70.0, 5.0)

	color_rect.modulate.a = 0.0
	var color_tween = get_tree().create_tween()
	color_tween.tween_property(color_rect, 'modulate:a', 1.0, 5.0)
	await color_tween.finished
	get_tree().change_scene_to_file("res://game/World.tscn")
