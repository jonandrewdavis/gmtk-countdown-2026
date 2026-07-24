extends RigidBody3D

@onready var area_3d: Area3D = $Area3D

var source: int

func _ready() -> void:
	area_3d.body_entered.connect(on_ball_hit)

func on_ball_hit(body: Node3D):
	print('doesnt fre')
	queue_free()
