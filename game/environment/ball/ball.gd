extends RigidBody3D

@onready var area_3d: Area3D = $Area3D

var source: int

func _ready() -> void:
	area_3d.body_entered.connect(on_ball_hit)
	# temp stuff
	await get_tree().create_timer(3.5).timeout
	queue_free()

func on_ball_hit(body: Node3D):
	if body is Enemy:
		body.health_system.damage(100)
