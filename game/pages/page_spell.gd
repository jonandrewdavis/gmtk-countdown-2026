@abstract
extends Control
class_name PageSpell

## Required by PageFlip2D's input handshake: its presence is what makes the book
## route mouse events into this page's SubViewport. Do not remove.
signal manage_pageflip(give_control_to_book: bool)

@export var spell: SpellSystem.SPELLS
@export var texture_progress_bar: TextureProgressBar
@export var control_group: Control

func _ready() -> void:
	texture_progress_bar.max_value = 1.0
	texture_progress_bar.value = 0.0
	for control in get_group_controls():
		control.focus_mode = Control.FOCUS_NONE
		if control is Slider:
			control.scrollable = false
		_setup_control(control)
	if Global.spell_system:
		Global.spell_system.cooldown_timers[spell].timeout.connect(_on_cooldown_finished)
		if is_on_cooldown():
			_start_cooldown_state()

func _process(_delta):
	if Global.spell_system:
		texture_progress_bar.value = Global.spell_system.get_spell_cooldown_time_left(spell)

func get_group_controls() -> Array[Control]:
	var controls: Array[Control] = []
	for child in control_group.get_children():
		if child is Control:
			controls.append(child)
	return controls

func is_on_cooldown() -> bool:
	return Global.spell_system != null and Global.spell_system.is_spell_on_cooldown(spell)

func activate(control: Control) -> void:
	if is_on_cooldown():
		return
	_activate(control)
	if _check_complete():
		_cast()

func _cast() -> void:
	Global.signal_spell_start.emit(spell)
	_start_cooldown_state()

func _start_cooldown_state() -> void:
	if Global.spell_system:
		texture_progress_bar.max_value = maxf(1.0, Global.spell_system.get_spell_cooldown(spell))
	for control in get_group_controls():
		_disable(control)

func _on_cooldown_finished() -> void:
	for control in get_group_controls():
		_reset(control)

@abstract func _setup_control(control: Control) -> void

@abstract func _activate(control: Control) -> void

@abstract func _check_complete() -> bool

@abstract func _disable(control: Control) -> void

@abstract func _reset(control: Control) -> void
