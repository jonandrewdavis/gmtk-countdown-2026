extends Node3D

@onready var topFace: = $Top
@onready var northFace: = $North
@onready var eastFace: = $East
@onready var southFace: = $South
@onready var westFace: = $West
@onready var bottomFace: = $Bottom

func update_faces(cell_list) -> void:
	var origin := global_transform.origin
	var my_grid_position := Vector2i(
		roundi(origin.x / Global.GRID_SIZE),
		roundi(origin.z / Global.GRID_SIZE))
	
	# delete face when there is another cell
	if cell_list.has(my_grid_position+Vector2i.RIGHT):
		eastFace.queue_free()
	if cell_list.has(my_grid_position+Vector2i.LEFT):
		westFace.queue_free()
	if cell_list.has(my_grid_position+Vector2i.DOWN):
		southFace.queue_free()
	if cell_list.has(my_grid_position+Vector2i.UP):
		northFace.queue_free()
