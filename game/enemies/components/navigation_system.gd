extends Node
class_name NavigationSystem

@export var nav_agent: NavigationAgent3D
@export var search_box: ShapeCast3D
@export var min_tick: float = 2.0
@export var max_tick: float = 4.0

const EYE_HEIGHT = 0.3
const SEARCH_DIRECTIONS = [Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]

var next_path_pos
var parent: CharacterBody3D

var timer_tick = Timer.new()
var timer_search = Timer.new()
var timer_navigate = Timer.new()
var timer_give_up = Timer.new()

func _ready() -> void:
	parent = get_parent()

	search_box.enabled = false

	add_child(timer_search)
	timer_search.timeout.connect(search_for_player)
	timer_search.one_shot = false
	randomize_timer(timer_search, 3.0, 5.0)

	# Navigation
	add_child(timer_navigate)
	timer_navigate.timeout.connect(update_navigation_path)
	timer_navigate.one_shot = false
	randomize_timer(timer_navigate, 0.1, 0.5)

	# Timers
	timer_give_up.timeout.connect(give_up)
	timer_give_up.wait_time = randf_range(2.0, 9.0)
	timer_give_up.one_shot = true # Do not repeatedly give up
	add_child(timer_give_up)

	add_child(timer_tick)
	timer_tick.timeout.connect(tick)
	timer_tick.one_shot = true
	start_tick()

func randomize_timer(timer: Timer, low: float, high: float) -> void:
	timer.wait_time = randf_range(low, high)
	timer.start()

func flat(vector: Vector3) -> Vector3:
	vector.y = 0.0
	return vector

func nav_map() -> RID:
	return NavigationServer3D.get_maps()[0]

func tick():
	start_tick()

	if parent.state == parent.States.SEARCHING:
		pick_patrol_destination()
	elif parent.state == parent.States.CHASING or parent.state == parent.States.HURTING:
		chase_target()

func start_tick():
	randomize_timer(timer_tick, min_tick, max_tick)

func cast_for_player(cast_target: Vector3):
	var previous_target = search_box.target_position
	search_box.target_position = cast_target
	search_box.force_shapecast_update()
	search_box.target_position = previous_target

	for i in search_box.get_collision_count():
		var body = search_box.get_collider(i)
		if body is Player:
			return body

	return null

func search_for_player():
	var player_found = null

	for direction in SEARCH_DIRECTIONS:
		player_found = cast_for_player(direction * Global.GRID_SIZE)
		if player_found:
			break

	if not player_found:
		player_found = cast_for_player(search_box.target_position)

	if player_found:
		found_player(player_found)
	elif parent.target and timer_give_up.is_stopped():
		timer_give_up.start()

# TODO: Setting & forgetting target might need to be signal emits?
func found_player(body: Node3D):
	timer_give_up.stop()

	if parent.target == body:
		return

	parent.target = body
	parent.set_state(parent.States.CHASING)

func give_up():
	print('give up')
	parent.set_state(parent.States.SEARCHING)

func chase_target():
	var target = parent.target
	if target:
		set_destination(NavigationServer3D.map_get_closest_point(nav_map(), target.global_transform.origin))

func retreat_from_target():
	var target = parent.target
	if not target:
		return

	var away = (parent.global_transform.origin - target.global_transform.origin).normalized()
	if away.is_zero_approx():
		away = -parent.global_transform.basis.z

	set_destination(NavigationServer3D.map_get_closest_point(nav_map(), parent.global_transform.origin + away * 6.0))

func set_destination(destination: Vector3):
	nav_agent.set_target_position(destination)
	next_path_pos = nav_agent.get_next_path_position()

func update_navigation_path():
	if nav_agent.is_navigation_finished() == false:
		next_path_pos = nav_agent.get_next_path_position()

const MIN_PATROL_DISTANCE_FROM_PLAYER = 2.0
const PATROL_STEPS = [1, 2]

var patrol_distance_left = INF

func pick_patrol_destination():
	if parent.has_arrived() == false:
		var distance_left = parent.distance_to_destination()
		if distance_left < patrol_distance_left - Global.GRID_SIZE * 0.25:
			patrol_distance_left = distance_left
			return

	patrol_distance_left = INF

	var map = nav_map()
	var player = get_tree().get_first_node_in_group('PlayerCharacter')
	var origin = parent.global_transform.origin
	origin.x = snappedf(origin.x, Global.GRID_SIZE)
	origin.z = snappedf(origin.z, Global.GRID_SIZE)

	if flat(parent.global_transform.origin - origin).length() > Global.GRID_SIZE * 0.3:
		set_destination(NavigationServer3D.map_get_closest_point(map, origin))
		return

	var directions = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	directions.shuffle()

	var crowded_fallback = null

	for direction in directions:
		var steps = PATROL_STEPS.pick_random()
		var candidate = origin + direction * steps * Global.GRID_SIZE
		var destination = NavigationServer3D.map_get_closest_point(map, candidate)

		if destination.distance_to(candidate) > Global.GRID_SIZE * 0.5:
			continue

		if is_walled_off(origin, direction, steps):
			continue

		if is_crowded(destination, player):
			if crowded_fallback == null:
				crowded_fallback = destination
			continue

		set_destination(destination)
		return

	if crowded_fallback != null:
		set_destination(crowded_fallback)

func is_crowded(destination: Vector3, player) -> bool:
	if player and flat(destination - player.global_transform.origin).length() < MIN_PATROL_DISTANCE_FROM_PLAYER:
		return true

	for enemy in get_tree().get_nodes_in_group('Enemies'):
		if enemy == parent:
			continue
		if flat(enemy.global_transform.origin - destination).length() < Global.GRID_SIZE * 0.5:
			return true

	return false

func is_walled_off(origin: Vector3, direction: Vector3, steps: int) -> bool:
	var space = parent.get_world_3d().direct_space_state

	for step in steps:
		var from = origin + direction * step * Global.GRID_SIZE + Vector3(0.0, EYE_HEIGHT, 0.0)
		var query = PhysicsRayQueryParameters3D.create(from, from + direction * Global.GRID_SIZE)
		query.collide_with_areas = false
		query.exclude = [parent.get_rid()]
		if not space.intersect_ray(query).is_empty():
			return true

	return false
