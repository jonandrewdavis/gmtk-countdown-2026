extends Control

## Required by PageFlip2D's input handshake: its presence is what makes the book
## route mouse events into this page's SubViewport. Do not remove.
signal manage_pageflip(give_control_to_book: bool)

# TOOD: Resource
@export var spell: Global.SPELLS
@export var timer_cooldown: float = 5.0

@onready var button: Button = %Button
@onready var texture_progress_bar: TextureProgressBar = %TextureProgressBar
@onready var timer: Timer = %Timer

@export var buttons_to_activate: Array[Button] = [] 

func _ready():
	timer.wait_time = timer_cooldown
	button.focus_mode = Control.FOCUS_NONE

	for this_button in buttons_to_activate:
		if !this_button: printerr('Missing button assignment')
		this_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		this_button.pressed.connect(activate.bind(this_button))

	texture_progress_bar.max_value = timer.wait_time
	texture_progress_bar.value = 0.0
	timer.timeout.connect(reset)

func start_cooldown():
	if timer.is_stopped() and all_buttons_ready():
		Global.signal_spell_start.emit(spell)
		texture_progress_bar.value = 0.0
		timer.start()

func _process(_delta):
	texture_progress_bar.value = timer.time_left

func activate(active_button: Button):
	active_button.disabled = true
	active_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	if buttons_to_activate.all(func(item: Button): return item.disabled == true):
		start_cooldown()
	
func all_buttons_ready():	
	return buttons_to_activate.all(func(item: Button): return item.disabled == true)	

func reset():
	for this_button in buttons_to_activate:
		this_button.disabled = false
		this_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
