extends PageSpell

var joystick: VirtualJoystick
var directions_hit := {}

@onready var cpu_particles: CPUParticles2D = %CPUParticles2D4

func _setup_control(control: Control) -> void:
	if control is VirtualJoystick:
		joystick = control
		joystick.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _process(delta):
	super(delta)
	if joystick == null or is_on_cooldown():
		return
	var output := Vector2(
		Input.get_action_strength(joystick.action_right) - Input.get_action_strength(joystick.action_left),
		Input.get_action_strength(joystick.action_down) - Input.get_action_strength(joystick.action_up)
	)
	if output.length() < 0.99:
		return
	var bucket := wrapi(roundi(output.angle() / TAU * 12), 0, 12)
	if not directions_hit.has(bucket):
		directions_hit[bucket] = true
		cpu_particles.visible = false
		activate(joystick)

func _activate(_control: Control) -> void:
	pass

func _check_complete() -> bool:
	return directions_hit.size() >= 12

func _disable(control: Control) -> void:
	if control is VirtualJoystick:
		var release := InputEventScreenTouch.new()
		release.index = 0
		release.pressed = false
		release.position = control.global_position + control.size / 2.0
		control.get_viewport().push_input(release, true)
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.mouse_default_cursor_shape = Control.CURSOR_ARROW
		

func _reset(control: Control) -> void:
	directions_hit.clear()
	cpu_particles.visible = true
	if control is VirtualJoystick:
		control.mouse_filter = Control.MOUSE_FILTER_STOP
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
