extends CanvasLayer
@onready var button_start: Button = %ButtonStart
@onready var color_rect: ColorRect = %ColorRect
@onready var main_margin: MarginContainer = %MainMargin
@onready var audio_stream_title: AudioStreamPlayer = %AudioStreamTitle
@onready var preview_camera: Camera3D = $MainMenu/WorldMenuPreview/Camera3D
@onready var slider_volume: HSlider = %SliderVolume

func _ready():

	button_start.pressed.connect(_start)

	slider_volume.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	slider_volume.value_changed.connect(_on_volume_changed)

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _start():
	var sasTween: Tween = create_tween()
	sasTween.set_ease(Tween.EASE_OUT)
	sasTween.tween_property(audio_stream_title, "volume_db", -35.0, 4.0)

	var text_tween = get_tree().create_tween()
	text_tween.tween_property(main_margin, 'modulate:a', 0.0, 0.4)
	
	var camera_tween = create_tween().set_trans(Tween.TRANS_SINE)
	camera_tween.tween_property(preview_camera, "fov", 70.0, 5.0)

	color_rect.modulate.a = 0.0
	var color_tween = get_tree().create_tween()
	color_tween.tween_property(color_rect, 'modulate:a', 1.0, 5.0)
	await color_tween.finished
	get_tree().change_scene_to_file("res://game/World.tscn")
