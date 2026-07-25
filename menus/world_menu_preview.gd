extends Node3D

const SWAY_SKEW := 0.02 # how far the treetops lean
const SWAY_SPEED := 0.8

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var trees: Array[Node] = $TreeGroup.get_children()

var time := 0.0


func _process(delta: float) -> void:
	world_environment.environment.sky_rotation.y += 0.005 * delta
	time += delta

	for i in trees.size():
		var tree: Sprite3D = trees[i]
		var skew := sin(time * SWAY_SPEED + float(i)) * SWAY_SKEW
		var shear := Basis.IDENTITY
		shear.x = Vector3(1.0, skew, 0.0)
		tree.transform.basis = tree.get_meta("base_basis") * shear


func _ready() -> void:
	for tree: Sprite3D in trees:
		tree.set_meta("base_basis", tree.transform.basis)
