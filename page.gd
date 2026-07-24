extends Control

## Required by PageFlip2D's input handshake: its presence is what makes the book
## route mouse events into this page's SubViewport. Do not remove.
signal manage_pageflip(give_control_to_book: bool)

# TOOD: Resource
@export var spell: Global.SPELLS

@export var timer_cooldown: float = 5.0

@onready var button: Button = $Button
@onready var texture_progress_bar: TextureProgressBar = $Button/TextureProgressBar
@onready var timer: Timer = $Timer

func _ready():
	timer.wait_time = timer_cooldown
	button.pressed.connect(start_cooldown)
	texture_progress_bar.max_value = timer.wait_time
	texture_progress_bar.value = 0.0

func start_cooldown():
	if timer.is_stopped():
		Global.signal_spell_start.emit(spell)
		texture_progress_bar.value = 0.0
		timer.start()

func _process(_delta):
	texture_progress_bar.value = timer.time_left
