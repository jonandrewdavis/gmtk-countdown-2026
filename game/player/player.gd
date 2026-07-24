extends CharacterBody3D

@export var speed_factor := 3.0
@export var direction := Vector3.FORWARD
@export var rotation_time := 0.2 * speed_factor
@export var move_time := 0.4 * speed_factor
@export var bob_height := 0.07

@onready var page_holder: Node2D = %PageHolder

const BALL = preload("uid://c1yny3sauy8yu")

@onready var forward: = $Ray_front
@onready var camera = $Camera3D

@onready var page_flip: PageFlip2D = %PageFlip

@onready var ice_color_rect: ColorRect = %IceColorRect
@onready var book_controls_raise: Control = %BookControlsRaise

var is_rotating := false
var is_moving := false

const OFFSET_START = Vector2(1.5, 2.25)
const OFFSET_ACTIVE = Vector2(1.5, 1.5)
var book_raise_tween: Tween

var count_down := 60

func _ready() -> void:
	_tween_book(OFFSET_START)
	page_holder.position = _book_target(OFFSET_START)

	Global.signal_spell_start.connect(show_spell)
	
	page_flip.signal_page_turn.connect(_on_page_turn)
	_on_page_turn(-1)
	label_countdown.text = str(count_down)

func _book_target(offset: Vector2) -> Vector2:
	return camera.get_viewport().get_visible_rect().get_center() * offset

func _tween_book(offset: Vector2) -> void:
	if book_raise_tween:
		book_raise_tween.kill()
	book_raise_tween = create_tween()
	book_raise_tween.tween_property(page_holder, "position", _book_target(offset), 0.5)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
		
	# BOOK 
	book_arrows.visible = offset == OFFSET_ACTIVE
	book_controls_raise.visible = offset == OFFSET_START


func _physics_process(_delta) -> void:
	if Input.is_action_just_pressed("raise_book"):
		_tween_book(OFFSET_ACTIVE)
	elif Input.is_action_just_released("raise_book"):
		_tween_book(OFFSET_START)
		return

	if Input.is_action_pressed("raise_book"):
		if Input.is_action_just_pressed("left"):
			page_flip.prev_page()
		elif Input.is_action_just_pressed('right'):
			page_flip.next_page()
		# Do not allow movement while raised.
		return


	if is_moving or is_rotating:
		return


	if Input.is_action_pressed("up"):
		move()
	if Input.is_action_pressed("left"):
		rotate_and_set_direction(90)
		await get_tree().create_timer(0.3).timeout
	if Input.is_action_pressed("right"):
		rotate_and_set_direction(-90)
		await get_tree().create_timer(0.3).timeout
	if Input.is_action_just_pressed('down'):
		move(-direction)

func collision_check(dir) -> bool:
	if dir != null:
		return dir.is_colliding()
	else:
		return false

func is_blocked(dir: Vector3) -> bool:
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + dir)
	query.exclude = [get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func move(move_dir: Vector3 = direction) -> void:
	if is_blocked(move_dir) or is_moving:
		return

	is_moving = true

	var target_position = global_position + move_dir
	
	var move_tween = get_tree().create_tween()
	move_tween.tween_property(self, "global_position", target_position, move_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	var bob_tween = get_tree().create_tween()
	var start_cam_y = camera.position.y
	
	bob_tween.tween_property(camera, "position:y", start_cam_y + bob_height, move_time / 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	bob_tween.tween_property(camera, "position:y", start_cam_y, move_time / 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
		
	await move_tween.finished
	is_moving = false
	count_down = count_down - 1 
	label_countdown.text = str(count_down)

@onready var label_countdown: Label = %LabelCountdown


#func _input(event) -> void:
	#if is_rotating:
		#return
	#if event.is_action_pressed("ui_down"):
		#rotate_and_set_direction(180)

func rotate_and_set_direction(angle_delta: float) -> void:
	is_rotating = true
	var new_y = rotation_degrees.y + angle_delta
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation_degrees:y", new_y, rotation_time).set_ease(Tween.EASE_OUT)
	await tween.finished
	direction = -global_transform.basis.z.normalized()
	is_rotating = false

# TODO: Page resource
# TOOD: Spell resource, effects, etc	
func show_spell(spell: Global.SPELLS):
	if spell == Global.SPELLS.ICE:
		ice_color_rect.show()
		await get_tree().create_timer(3.0).timeout
		var tween = get_tree().create_tween()
		tween.tween_property(ice_color_rect.material, 'shader_parameter/vignette_strength', 0.0, 2.0)
		await tween.finished
		ice_color_rect.hide()
		ice_color_rect.material['shader_parameter/vignette_strength'] = 1.5
	elif spell == Global.SPELLS.FIRE:
		shoot()
		
func shoot():
	var force = 10
	var pos = camera.global_position
	var shoot_dir = get_shoot_direction()
	var new_ball: RigidBody3D = BALL.instantiate()
	get_tree().current_scene.add_child(new_ball, true)
	new_ball.global_position = pos + Vector3(0.0, 1.0, 0.0)
	new_ball.apply_central_impulse(shoot_dir * force)

func get_shoot_direction():
	var viewport_rect = get_viewport().get_visible_rect().size
	var raycast_start = camera.project_ray_origin(viewport_rect / 2)
	var raycast_end = raycast_start + camera.project_ray_normal(viewport_rect / 2) * 200
	return -(raycast_start - raycast_end).normalized()

@onready var control_d: TextureRect = %ControlD
@onready var control_a: TextureRect = %ControlA
@onready var arrow_left: TextureRect = %ArrowLeft
@onready var arrow_right: TextureRect = %ArrowRight
@onready var book_arrows: Control = %BookArrows

func _on_page_turn(spread_index: int):
	if spread_index >= 0:
		control_a.show()
		arrow_left.show()
	else:
		control_a.hide()
		arrow_left.hide()
