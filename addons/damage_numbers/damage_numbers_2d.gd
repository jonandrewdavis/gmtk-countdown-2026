class_name DamageNumbers2D
extends CanvasLayer

const DAMAGE_NUMBER := preload("res://addons/damage_numbers/damage_number_2d.tscn")

@export var color := Color.WHITE
@export var number_scale := 1.0
@export var height := 240.0
@export var spread := 90.0
@export var duration := 1.4
@export var center_offset := Vector2(0.0, -60.0)
@export var center_jitter := Vector2(160.0, 80.0)

var pool: Array[DamageNumber2D] = []

func spawn(value: int, at: Vector2) -> void:
	var number := _get_number()
	add_child(number)
	number.scale = Vector2(number_scale, number_scale)
	number.position = at
	number.set_values_and_animate(str(value), Vector2.ZERO, height, spread, duration, color)

func spawn_centered(value: int) -> void:
	var center := get_viewport().get_visible_rect().size * 0.5 + center_offset
	spawn(value, center + Vector2(
		randf_range(-center_jitter.x, center_jitter.x),
		randf_range(-center_jitter.y, center_jitter.y)
	))


func _get_number() -> DamageNumber2D:
	if not pool.is_empty():
		return pool.pop_front()

	var number: DamageNumber2D = DAMAGE_NUMBER.instantiate()
	number.tree_exiting.connect(func(): pool.append(number))
	return number
