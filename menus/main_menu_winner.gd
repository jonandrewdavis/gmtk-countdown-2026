extends CanvasLayer

@onready var button_embrace: Button = %ButtonEmbrace
@onready var button_destroy: Button = %ButtonDestroy
@onready var color_rect: ColorRect = %ColorRect
@onready var win_modal: PanelContainer = %WinModal
@onready var camera_3d: Camera3D = $WorldMenuPreview/Camera3D
@onready var thank_you: CenterContainer = %ThankYou

const GHOST_DEATH = preload("uid://d17fnnelf6pbc")

func _ready() -> void:
	color_rect.modulate.a = 0.0
	button_embrace.pressed.connect(_choice)
	button_destroy.pressed.connect(_choice)
	SoundManager.crossfade_bgm(null, 2.0)

func _choice():
	var text_tween = get_tree().create_tween()
	text_tween.tween_property(win_modal, 'modulate:a', 0.0, 0.4)
	
	var camera_tween = create_tween().set_trans(Tween.TRANS_SINE)
	camera_tween.tween_property(camera_3d, "fov", 70.0, 5.0)
	SoundManager.play_sfx(GHOST_DEATH)
	
	color_rect.modulate.a = 0.0
	var color_tween = get_tree().create_tween()
	color_tween.tween_property(color_rect, 'modulate:a', 1.0, 5.0)
	await color_tween.finished
	thank_you.show()
