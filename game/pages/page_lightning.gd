extends PageSpell

func _setup_control(control: Control) -> void:
	if control is Slider:
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		control.value_changed.connect(_on_slider_value_changed.bind(control))

func _on_slider_value_changed(value: float, slider: Slider) -> void:
	slider.get_node("Particles").hide()
	if value >= slider.max_value:
		activate(slider)

func _activate(control: Control) -> void:
	_disable(control)

func _check_complete() -> bool:
	return get_group_controls().all(func(item): return item is Slider and item.value >= item.max_value)

func _disable(control: Control) -> void:
	if control is Slider:
		control.editable = false
		control.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _reset(control: Control) -> void:
	if control is Slider:
		control.get_node("Particles").show()
		control.set_value_no_signal(control.min_value)
		control.editable = true
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
