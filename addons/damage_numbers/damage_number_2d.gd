class_name DamageNumber2D
extends Node2D

@onready var label: Label = %Label
@onready var label_container: Node2D = %LabelContainer
@onready var ap: AnimationPlayer = %AnimationPlayer


func set_values_and_animate(value: String, start_pos: Vector2, height: float, spread: float, duration: float = 0.0) -> void:
	label.text = value
	var anim_length = ap.get_animation("Rise and Fade").length
	var tween_length = duration if duration > 0.0 else anim_length
	ap.speed_scale = anim_length / tween_length
	ap.play("Rise and Fade")

	var tween = get_tree().create_tween()
	var end_pos = Vector2(randf_range(-spread, spread), -height) + start_pos

	tween.tween_property(label_container, "position", end_pos, tween_length).from(start_pos)


func remove() -> void:
	ap.stop()
	if is_inside_tree():
		get_parent().remove_child(self)
