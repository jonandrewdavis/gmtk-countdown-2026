# TODO: Beehave or some other behavioral tree when this state machine gets to be too much
# TODO: Random pauses between choosing another action? "Global cool down" like
# TODO: Assure this is completely server authoratative
# TODO: Perf test navigation agent to assure it doesn't consume to much CPU or cause FPS loss

extends CharacterBody3D

class_name Enemy

# TODO: Resource these if we have at least 3.
enum TYPE { 
	GHOST,
	KNIGHT
}

@onready var GHOST_MESH: Node3D = %Enemy_Ghost_Rigged
@onready var KNIGHT_MESH: Node3D = %Enemy_Knight_Rigged

var animation_player_current: AnimationPlayer
@onready var animation_player_knight: AnimationPlayer = $Enemy_Knight_Rigged/AnimationPlayer
@onready var animation_player_ghost: AnimationPlayer = $Enemy_Ghost_Rigged/AnimationPlayer

const RIG_ANI = {
	TYPE.GHOST: { idle = &"ghost_Idle", attack = &"ghost_attack", death = &"ghost_death" },
	TYPE.KNIGHT: { idle = &"Knight_Idle", attack = &"Knight_Attack", death = &"Knight_Death" },
}

var hurt_flash_material := StandardMaterial3D.new()
var hurt_tween: Tween

@export var enemy_type: TYPE

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const FRICTION = 1.0
const ROTATION_SPEED = 2.0

@export_category("Enemy Required Nodes")
@export var animation_player: AnimationPlayer 
@export var health_system: HealthSystem
@export var nav: NavigationSystem
@export var nav_agent: NavigationAgent3D
@export var search_box: ShapeCast3D
@export var attack_box: Area3D
@export var detection_box: Area3D

# TODO: Weak points and eyeline
# TODO: Give up chase 
#@export var hit_box: Area3D
#@export var eyeline: Area3D 

@export_category("Enemy Stats")
@export var max_speed = 0.4
@export var speed = max_speed
@export var attack_value: int = 20
@export var attack_value_max: int = 30

const RETREAT_CHANCE = 0.45
const ATTACK_RANGE = 1.2
const ARRIVE_DISTANCE = 0.8
const MIN_ALIGNMENT = 0.25
const CHASE_BREAK_DISTANCE = 2.0
const CHASE_BREAK_CHANCE = 0.4

var timer_attack_cooldown = Timer.new()
var timer_retreat = Timer.new()
var timer_retreat_cooldown = Timer.new()


var target = null:
	set(value):
		if target == value:
			return
		target = value
		Global.signal_enemy_target_changed.emit()

@onready var AudioPlayerAmbient: AudioStreamPlayer3D = $AudioStreamPlayer3DAmbient

@export var AmbientSoundsArray: Array[AudioStream]

@onready var AudioPlayerAttack: AudioStreamPlayer3D = $AudioStreamPlayer3DAttack

@export var AttackSoundsArray: Array[AudioStream]

# ANIMATION LIST. These are required
enum LIST { 
	WALK,
	IDLE,
	ATTACK,
	HURT,
	DYING,
	DECAY
}

# ANIMATION LIST. These are required
const ANI = [
	&"walk2", # Walk
	&"idle", # Idle
	&"attack", # Attack
	&"hurt", # Hurt
	&"dying", # Dying
	&"RESET" # Decay
]

# This enum lists all the possible states the character can be in.
enum States { IDLE, SEARCHING, CHASING, ATTACKING, HURTING, DODGING, DYING, DECAYING }

# This variable keeps track of the character's current state.
var state: States = States.IDLE

func _ready():
	add_to_group("Enemies")

	var attack_time_freq = randf_range(6.0, 10.0)

	animation_player_current = animation_player_ghost

	if enemy_type == TYPE.GHOST:
		animation_player_current = animation_player_ghost
		print("IM A GHOST")
		
	if enemy_type == TYPE.KNIGHT:
		health_system.max_health = 250
		health_system.heal(250)
		attack_time_freq = randf_range(3.0, 7.0)
		attack_value = 40
		attack_value_max = 50
		GHOST_MESH.hide()
		KNIGHT_MESH.show()
		speed = max_speed * 1.2
		animation_player_current = animation_player_knight
		print("IM A KNIGHT")
	
	animation_player.playback_default_blend_time = 0.4

	animation_player_current.playback_default_blend_time = 0.4
	animation_player_current.animation_finished.connect(on_current_animation_finished)
	animation_player_current.play(RIG_ANI[enemy_type].idle)

	hurt_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hurt_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hurt_flash_material.albedo_color = Color(1, 1, 1, 0)
	damage_overlay_material(GHOST_MESH, hurt_flash_material)
	damage_overlay_material(KNIGHT_MESH, hurt_flash_material)

	nav_agent.path_desired_distance = 0.15
	nav_agent.target_desired_distance = randf_range(0.5, 0.65)
	nav_agent.radius = 0.12
	nav_agent.avoidance_enabled = false

	attack_box.body_entered.connect(on_attack_box_entered)
	detection_box.body_entered.connect(on_detection_box_entered)
	detection_box.body_exited.connect(on_detection_box_exited)
	animation_player.animation_finished.connect(on_animation_finished)
	
	# Health
	health_system.signal_hurt.connect(on_hurt)
	health_system.signal_death.connect(on_death)

	# Nav
	#nav_agent.navigation_finished.connect(on_navigation_finished)
	nav_agent.path_changed.connect(on_path_changed)

	add_child(timer_attack_cooldown)
	timer_attack_cooldown.timeout.connect(attack)
	timer_attack_cooldown.wait_time = attack_time_freq
	timer_attack_cooldown.start()

	add_child(timer_retreat)
	timer_retreat.timeout.connect(end_retreat)
	timer_retreat.one_shot = true

	add_child(timer_retreat_cooldown)
	timer_retreat_cooldown.wait_time = 0.4
	timer_retreat_cooldown.one_shot = true

	await get_tree().create_timer(0.2).timeout
	set_state(States.SEARCHING)

	#ambient sounds stuff 
	_play_new_random_ambient_sound()
	
func _play_new_random_ambient_sound() -> void:
	await get_tree().create_timer(randf_range(0.5, 10.0)).timeout
	if AmbientSoundsArray.size() > 0:
		var RandomAmbientSound: AudioStream = AmbientSoundsArray.pick_random()
		AudioPlayerAmbient.stream = RandomAmbientSound
		AudioPlayerAmbient.play()
	
func _play_random_attack_sound() -> void:
	if AttackSoundsArray.size() > 0:
		var RandomAttackSound: AudioStream = AttackSoundsArray.pick_random()
		AudioPlayerAttack.stream = RandomAttackSound
		AudioPlayerAttack.play()

func _physics_process(delta: float) -> void:
	match state:
		States.SEARCHING:
			move_and_look(delta)
		States.CHASING, States.HURTING, States.DODGING:
			move_and_look(delta)
		States.ATTACKING:
			move_and_attack(delta)
		States.DYING:
			velocity = Vector3.ZERO
		States.DECAYING:
			velocity = Vector3.ZERO
	
	velocity.y -= gravity * delta

	move_and_slide()
	
func move_and_attack(delta):
	if target:
		face_position(target.global_transform.origin, delta)

	if global_position.distance_to(attack_position) > 0.8:
		move_towards(attack_position, speed)
	else:
		set_state(States.CHASING)
		nav.chase_target()

func distance_to_destination() -> float:
	var to_destination = nav_agent.target_position - global_transform.origin
	to_destination.y = 0.0
	return to_destination.length()

func has_arrived() -> bool:
	return nav_agent.is_navigation_finished() or distance_to_destination() < ARRIVE_DISTANCE

func move_and_look(delta):
	if has_arrived() == false:
		move_towards(nav.next_path_pos, speed)
		face_position(nav.next_path_pos, delta)
		return

	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)

	if target and state != States.DODGING:
		face_position(target.global_transform.origin, delta)

func move_towards(destination, move_speed):
	var direction = destination - global_transform.origin
	direction.y = 0.0
	direction = direction.normalized()

	var facing = -global_transform.basis.z
	var alignment = clampf(Vector2(facing.x, facing.z).normalized().dot(Vector2(direction.x, direction.z)), MIN_ALIGNMENT, 1.0)

	velocity.x = direction.x * move_speed * alignment
	velocity.z = direction.z * move_speed * alignment

func face_position(look_target, delta):
	var direction = look_target - global_position
	direction.y = 0.0
	if direction.is_zero_approx():
		return

	var facing = -global_transform.basis.z
	var current_yaw = atan2(-facing.x, -facing.z)
	var desired_yaw = atan2(-direction.x, -direction.z)
	rotation = Vector3(0.0, rotate_toward(current_yaw, desired_yaw, ROTATION_SPEED * delta), 0.0)


func set_state(new_state: States) -> void:
	var previous_state := state
	state = new_state

	############
	# You can check both the previous and the new state to determine what to do when the state changes. 
	# This checks the previous state.

	#print("STATE", States.keys()[state])
	# Never leave Dying unless it's to decay. TODO: No decay state.
	if previous_state == States.DYING and new_state != States.DECAYING: 
		return

	# Never leave Decaying.
	if previous_state == States.DECAYING: 
		return

	if previous_state == States.ATTACKING && new_state == States.HURTING:
		animation_player.play(ANI[LIST.HURT])
		return
				

	#if previous_state == States.ATTACKING && animation_player.current_animation == ANI[LIST.ATTACK]: 
		#return
#
	#if health_system.health == 0 and state != States.DYING:
		#set_state(States.DYING)
		#return

	#############
	# Here, I check the new state.
	if state == States.SEARCHING:
		target = null
		if not animation_player.current_animation == ANI[LIST.HURT]:
			animation_player.play(ANI[LIST.WALK])
		speed = max_speed * 0.6
		nav.pick_patrol_destination()
		pass

	if state == States.CHASING:
		if not animation_player.current_animation == ANI[LIST.HURT]:
			animation_player.play(ANI[LIST.WALK])
		nav.chase_target()
		speed = max_speed
		pass

	if state == States.DODGING:
		animation_player.play(ANI[LIST.WALK])
		speed = max_speed * 0.8
		nav.retreat_from_target()
		timer_retreat.wait_time = randf_range(2.0, 5.0)
		timer_retreat.start()

	# THIS does the actual attack
	if state == States.ATTACKING:
		animation_player.play(ANI[LIST.ATTACK])
		animation_player_current.play(RIG_ANI[enemy_type].attack)
		# TODO: await an animation but we're not sure if the current animation is in action, etc.
		await get_tree().create_timer(0.5).timeout
		attack_box.set_deferred('monitoring', true)
	#else:
		#attack_box.set_deferred('monitoring', false)
	
	if state == States.HURTING:
		if health_system.health == 0:
			return
		animation_player.play(ANI[LIST.HURT])
		# TODO: interrupt whever we are doing to get hurt. Maybe a 33% chance to? 
		var get_player = get_tree().get_first_node_in_group('PlayerCharacter')
		if get_player:
			target = get_player
			#set_state(States.CHASING)

	if state == States.DYING:
		target = null
		# Helps prevent monitoring issues
		nav.timer_tick.stop()
		nav.timer_navigate.stop()
		nav.timer_give_up.stop()
		nav.timer_search.stop()
		timer_retreat.stop()
		animation_player.play(ANI[LIST.DYING])
		animation_player_current.play(RIG_ANI[enemy_type].death)
		set_process(false)
		await get_tree().create_timer(2.0).timeout
		queue_free()
		# Decay triggered by animation

	if state == States.DECAYING:
		animation_player.play(ANI[LIST.DECAY])
		decay()
		pass

func decay():
	await get_tree().create_timer(10.0).timeout
	set_process(false) # could queue free on animation finishedf
	await get_tree().process_frame
	queue_free()

func on_animation_finished(animation_name):
	if state == States.DODGING:
		return

	if animation_name == ANI[LIST.HURT]:
		if target:
			set_state(States.CHASING)
			#animation_player.play(ANI[LIST.IDLE])

	if animation_name == ANI[LIST.ATTACK]:
		set_state(States.CHASING)

func on_current_animation_finished(animation_name):
	if animation_name == RIG_ANI[enemy_type].attack:
		animation_player_current.play(RIG_ANI[enemy_type].idle)

func damage_overlay_material(node: Node, overlay: Material) -> void:
	if node is MeshInstance3D:
		node.material_overlay = overlay
	for child in node.get_children():
		damage_overlay_material(child, overlay)

func play_hurt_flash():
	if hurt_tween and hurt_tween.is_running():
		return
	hurt_flash_material.albedo_color.a = 0.7
	hurt_tween = create_tween()
	hurt_tween.tween_property(hurt_flash_material, "albedo_color:a", 0.0, 0.2)
	hurt_tween.tween_interval(0.3)

func on_hurt(_damage_value: int = 0):
	play_hurt_flash()
	set_state(States.HURTING)
	Global.signal_enemy_damaged.emit(_damage_value)
	# Whenever we recieve damage, stop attacking for a moment
	if check_retreat_chance():
		set_state(States.DODGING)
	else:
		# we didn't retreat, start the cooldown before checking again
		timer_retreat_cooldown.start()

func check_retreat_chance() -> bool:
	return health_system.health > 0 \
	and state == States.HURTING \
	and randf() < RETREAT_CHANCE \
	and timer_retreat_cooldown.is_stopped()\
	and enemy_type != TYPE.KNIGHT # knights never retreat.
	
func end_retreat():
	if state != States.DODGING:
		return

	if target:
		set_state(States.CHASING)
	else:
		set_state(States.SEARCHING)


func on_death():
	# TODO: #CRITICAL " DEATH PROPER
	set_state(States.DYING)

func can_attack() -> bool:
	if not target:
		return false
		
	if health_system.health == 0:
		return false
		
	if state in [States.ATTACKING, States.DYING, States.DECAYING, States.DODGING]:
		return false

	return true


var attack_position

func attack():
	if can_attack() == false:
		return
	# TODO: Pick a position on the left or the right of the player.
	if state == States.CHASING or state == States.HURTING:
		var to_target = target.global_transform.origin - global_transform.origin
		to_target.y = 0.0
		if to_target.length() <= ATTACK_RANGE:
			attack_position = target.global_transform.origin + Vector3(0.0, 0.1, 0.0)
			set_state(States.ATTACKING)

func on_path_changed():
	if health_system.health == 0.0:
		set_state(States.DYING)
		return

	if state == States.ATTACKING:
		return

	if animation_player.current_animation == ANI[LIST.IDLE]:
		animation_player.play(ANI[LIST.WALK])
		
	if animation_player.current_animation == ANI[LIST.HURT]:
		animation_player.play(ANI[LIST.WALK])

var player_adjacent := false

func on_detection_box_entered(body):
	if not body.is_in_group('PlayerCharacter'):
		return

	player_adjacent = true

	if state in [States.DYING, States.DECAYING, States.ATTACKING]:
		return

	if target != body or state != States.CHASING:
		target = body
		set_state(States.CHASING)

func on_detection_box_exited(body):
	if body.is_in_group('PlayerCharacter'):
		player_adjacent = false

func try_break_chase() -> bool:
	if state != States.CHASING or player_adjacent or not target:
		return false

	var to_target = target.global_transform.origin - global_transform.origin
	to_target.y = 0.0
	if to_target.length() < CHASE_BREAK_DISTANCE * Global.GRID_SIZE:
		return false

	if randf() < CHASE_BREAK_CHANCE:
		target = null
		set_state(States.SEARCHING)
		return true

	return false

func on_attack_box_entered(body):
	if body.is_in_group('PlayerCharacter') or body.is_in_group('Goat'):
		if not body.get('health_system'):
			return
		body.health_system.damage(randi_range(attack_value, attack_value_max), 4)
		attack_box.set_deferred('monitoring', false)

func _on_audio_stream_player_3d_ambient_finished() -> void:
	_play_new_random_ambient_sound()
