extends PageSpell

func _setup_control(control: Control) -> void:
	if control is Button:
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		control.pressed.connect(activate.bind(control))

func _activate(control: Control) -> void:
	_disable(control)

func _check_complete() -> bool:
	return get_group_controls().all(func(item): return item is Button and item.disabled)

func _disable(control: Control) -> void:
	if control is Button:
		control.disabled = true
		control.mouse_default_cursor_shape = Control.CURSOR_ARROW
		if control.get_child_count() > 0:
			control.get_child(0).hide()

func _reset(control: Control) -> void:
	if control is Button:
		control.disabled = false
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if control.get_child_count() > 0:
			control.get_child(0).show()
