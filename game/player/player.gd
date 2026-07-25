extends CharacterBody3D
class_name Player

const DEFAULT_SPEED := 3.0
@export var speed_factor := DEFAULT_SPEED
@export var direction := Vector3.FORWARD
@export var rotation_time := 0.2 * speed_factor
@export var move_time := 0.4 * speed_factor
@export var bob_height := 0.07

const BALL = preload("uid://c1yny3sauy8yu")
const RAY_LENGTH := 0.55

@onready var camera = $Camera3D
@onready var page_holder: Node2D = %PageHolder
@onready var page_flip: PageFlip2D = %PageFlip
@onready var ice_color_rect: ColorRect = %IceColorRect
@onready var book_controls_raise: Control = %BookControlsRaise
@onready var book_arrows: Control = %BookArrows
@onready var control_a: TextureRect = %ControlA
@onready var arrow_left: TextureRect = %ArrowLeft
@onready var label_countdown: Label = %LabelCountdown
@onready var transition_rect: ColorRect = %TransitionRect
@onready var health_bar: ProgressBar = %HealthBar
@onready var hurt_color_rect: ColorRect = %HurtColorRect
@onready var health_system: HealthSystem = %HealthSystem
@onready var timer_ice_shield: Timer = %TimerIceShield
@onready var damage_numbers_player: DamageNumbers2D = %DamageNumbersPlayer
@onready var damage_numbers_enemy: DamageNumbers2D = %DamageNumbersEnemy

var is_rotating := false
var is_moving := false

const OFFSET_START = Vector2(1.5, 2.25)
const OFFSET_ACTIVE = Vector2(1.5, 1.5)
var book_raise_tween: Tween

var count_down := 60

var hurt_tween: Tween
var last_health := -1

func _ready() -> void:
	add_to_group('PlayerCharacter')
	ready_spell_timers()
	
	transition_rect.material.set_shader_parameter('inner_radius', -0.1)
	transition_rect.material.set_shader_parameter('outer_radius', 0.0)
	transition_rect.show()

	_tween_book(OFFSET_START)
	page_holder.position = _book_target(OFFSET_START)

	Global.signal_spell_start.connect(show_spell)
	Global.signal_enemy_damaged.connect(_on_enemy_damaged)

	health_system.signal_max_health_updated.connect(_on_max_health_updated)
	health_system.signal_health_updated.connect(_on_health_updated)
	health_system.signal_hurt.connect(_on_hurt)
	health_system.signal_death.connect(_on_death)
	_on_max_health_updated(health_system.max_health)
	_on_health_updated(health_system.health)

	page_flip.signal_page_turn.connect(_on_page_turn)
	_on_page_turn(-1) # turn to cover page to get the book in position

	label_countdown.text = str(count_down)


func _on_max_health_updated(max_health: int) -> void:
	health_bar.max_value = max_health

func _on_health_updated(health: int) -> void:
	if last_health > health:
		damage_numbers_player.spawn(last_health - health,
			health_bar.global_position + Vector2(health_bar.size.x * 0.5, health_bar.size.y + 30.0))
	last_health = health
	health_bar.value = health

func _on_enemy_damaged(amount: int) -> void:
	damage_numbers_enemy.spawn_centered(amount)

func can_be_damaged() -> bool:
	if not timer_ice_shield.is_stopped():
		return false
		
	return true

func _on_hurt() -> void:	
	if hurt_tween:
		hurt_tween.kill()

	hurt_color_rect.show()
	hurt_tween = create_tween().set_trans(Tween.TRANS_SINE)
	hurt_tween.tween_property(hurt_color_rect.material, 'shader_parameter/vignette_strength', 1.4, 0.07)\
		.set_ease(Tween.EASE_OUT)
	hurt_tween.tween_property(hurt_color_rect.material, 'shader_parameter/vignette_strength', 0.0, 0.6)\
		.set_ease(Tween.EASE_IN)
	hurt_tween.tween_callback(hurt_color_rect.hide)

func _on_death() -> void:
	health_bar.value = 0
	# TODO: game over

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
	elif Input.is_action_pressed("left"):
		rotate_and_set_direction(90)
	elif Input.is_action_pressed("right"):
		rotate_and_set_direction(-90)
	elif Input.is_action_just_pressed('down'):
		move(-direction)

func is_blocked(move_dir: Vector3) -> bool:
	var from := global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + move_dir.normalized() * RAY_LENGTH)
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func move(move_dir: Vector3 = direction) -> void:
	if is_blocked(move_dir):
		return

	is_moving = true

	var target_position = global_position + move_dir
	target_position.x = snappedf(target_position.x, Global.GRID_SIZE)
	target_position.z = snappedf(target_position.z, Global.GRID_SIZE)
	
	# moving backwards is slower, so it pays to turn around.
	if move_dir.dot(direction) < 0.0:
		move_time = move_time * 1.4

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
	count_down -= 1
	label_countdown.text = str(count_down)
	# reset speed if backwards was done
	move_time = 0.4 * speed_factor

func rotate_and_set_direction(angle_delta: float) -> void:
	is_rotating = true
	var new_y = rotation_degrees.y + angle_delta
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation_degrees:y", new_y, rotation_time).set_ease(Tween.EASE_OUT)
	await tween.finished
	# snap
	direction = (-global_transform.basis.z).snappedf(1.0)
	print(direction)
	is_rotating = false

func ready_spell_timers():
	timer_ice_shield.one_shot = true
	timer_ice_shield.wait_time = 3.0
	timer_ice_shield.timeout.connect(func(): remove_spell(Global.SPELLS.ICE))

# TODO: Page resource
# TOOD: Spell resource, effects, etc	
func show_spell(spell: Global.SPELLS):
	if spell == Global.SPELLS.ICE:
		ice_color_rect.show()
		timer_ice_shield.start()
	elif spell == Global.SPELLS.FIRE:
		shoot()

func remove_spell(spell: Global.SPELLS):
	if spell == Global.SPELLS.ICE:
		var tween = get_tree().create_tween()
		tween.tween_property(ice_color_rect.material, 'shader_parameter/vignette_strength', 0.0, 2.0)
		# Fades out
		await tween.finished
		ice_color_rect.hide()
		ice_color_rect.material['shader_parameter/vignette_strength'] = 1.5		


func shoot():
	var force = 1.0
	var shoot_dir = get_shoot_direction()
	var new_ball: RigidBody3D = BALL.instantiate()
	get_tree().current_scene.add_child(new_ball, true)
	new_ball.global_position = camera.global_position + shoot_dir * 0.1
	new_ball.apply_central_impulse(shoot_dir * force)

func get_shoot_direction() -> Vector3:
	return camera.project_ray_normal(get_viewport().get_visible_rect().size / 2.0)

func _on_page_turn(spread_index: int):
	if spread_index >= 0:
		control_a.show()
		arrow_left.show()
	else:
		control_a.hide()
		arrow_left.hide()

func fade_in() -> void:
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(transition_rect.material, 'shader_parameter/outer_radius', 1.2, 2.5)
	tween.parallel().tween_property(transition_rect.material, 'shader_parameter/inner_radius', 0.85, 2.5)
	await tween.finished
	transition_rect.hide()
