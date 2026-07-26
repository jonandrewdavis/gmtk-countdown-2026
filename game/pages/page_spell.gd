@abstract
extends Control
class_name PageSpell

## Required by PageFlip2D's input handshake: its presence is what makes the book
## route mouse events into this page's SubViewport. Do not remove.
signal manage_pageflip(give_control_to_book: bool)

@export var spell: SpellSystem.SPELLS
@export var texture_progress_bar: TextureProgressBar
@export var timer: Timer
@export var control_group: Control

func _ready() -> void:
	texture_progress_bar.max_value = 1.0
	texture_progress_bar.value = 0.0
	timer.one_shot = true
	timer.timeout.connect(_on_cooldown_finished)
	for control in get_group_controls():
		_setup_control(control)

func _process(_delta):
	texture_progress_bar.value = timer.time_left

func get_group_controls() -> Array[Control]:
	var controls: Array[Control] = []
	for child in control_group.get_children():
		if child is Control:
			controls.append(child)
	return controls

func is_on_cooldown() -> bool:
	return not timer.is_stopped()

func activate(control: Control) -> void:
	if is_on_cooldown():
		return
	_activate(control)
	if _check_complete():
		_cast()

func _cast() -> void:
	for control in get_group_controls():
		_disable(control)
	Global.signal_spell_start.emit(spell)
	var cooldown := 1.0
	if Global.spell_system:
		cooldown = Global.spell_system.get_spell_cooldown(spell)
	texture_progress_bar.max_value = cooldown
	timer.wait_time = cooldown
	timer.start()

func _on_cooldown_finished() -> void:
	await get_tree().process_frame
	texture_progress_bar.value = 0.0
	for control in get_group_controls():
		_reset(control)

@abstract func _setup_control(control: Control) -> void

@abstract func _activate(control: Control) -> void

@abstract func _check_complete() -> bool

@abstract func _disable(control: Control) -> void

@abstract func _reset(control: Control) -> void
