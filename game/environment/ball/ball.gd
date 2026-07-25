extends RigidBody3D

@onready var area_3d: Area3D = $Area3D

var source: int

@onready var timer_fire_damage: Timer = %TimerFireDamage

const FIRE_TICK_TIME = 0.2
const FIRE_TICK_DAMAGE = 5
const FIRE_DUR = 3.0

func _ready() -> void:
	area_3d.body_entered.connect(on_ball_entered)
	timer_fire_damage.wait_time = FIRE_TICK_TIME

	await get_tree().create_timer(FIRE_DUR).timeout
	queue_free()

func on_ball_entered(body: Node3D):
	if body is Enemy:
			timer_fire_damage.timeout.connect(_deal_fire_tick.bind(body))
			timer_fire_damage.start()

func _deal_fire_tick(body: Enemy):
	body.health_system.damage(FIRE_TICK_DAMAGE)
