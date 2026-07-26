extends Node3D
class_name SpellSystem

# TODO: spell resource:
# cooldown
# duration
# mesh?
# overlay?
# Difficult because they can have multiple or varying effects.
@onready var area_fire: Area3D = %AreaFire
@onready var area_lightning: Area3D = %AreaLightning

@onready var timer_fire_damage: Timer = %TimerFireDamage
@onready var timer_ice_prevent_damage: Timer = %TimerIcePreventDamage
@onready var canvas_layer_ice: CanvasLayer = %CanvasLayerIce

enum SPELLS {
	ICE,
	FIRE,
	HEAL,
	SACRIFICE,
	LIGHTNING
}

var SPELL_COOLDOWNS = { 
	"ICE": 12.0,
	"FIRE": 8.0, # longer since it lasts awhile
	"HEAL": 0.0,
	"SACRIFICE": 0.0,
	"LIGHTNING": 4.0,
}

const FIRE_TICK_TIME = 0.2
const FIRE_TICK_DAMAGE = 5
const FIRE_DUR = 3.0

const LIGHTNING_BLINK_TIME = 0.25
const LIGHTNING_BLINKS = 3
const LIGHTNING_CLEANUP_TIME = 0.33
const LIGHTNING_DAMAGE_MIN = 25
const LIGHTNING_DAMAGE_MAX = 50

const ICE_DAMAGE_PREVENT_TIMER = 8.0

func get_spell_cooldown(SPELL):
	return SPELL_COOLDOWNS.get(SPELLS.keys()[SPELL])

func is_damage_prevented() -> bool:
	return not timer_ice_prevent_damage.is_stopped()

func _ready() -> void:
	Global.spell_system = self
	Global.signal_spell_start.connect(spell_start)
	for current_node in get_children():
		if current_node is Area3D:
			current_node.visible = false
			current_node.monitorable = false
			current_node.monitoring = false
	
	# Spell specific
	area_lightning.body_entered.connect(on_lightning_entered)
	timer_fire_damage.wait_time = FIRE_TICK_TIME
	timer_fire_damage.timeout.connect(deal_fire_tick)
	timer_ice_prevent_damage.wait_time = ICE_DAMAGE_PREVENT_TIMER
	timer_ice_prevent_damage.timeout.connect(func(): canvas_layer_ice.visible = false)
	
	area_fire.top_level = true

func _process(_delta: float) -> void:
	area_fire.global_position.x = global_position.x
	area_fire.global_position.z = global_position.z


# Godot match statements break automatically.
func spell_start(spell: SPELLS):
	match spell:
		SPELLS.ICE:
			canvas_layer_ice.visible = true
			timer_ice_prevent_damage.start()
		SPELLS.FIRE:
			area_fire.visible = true
			area_fire.monitoring = true
			timer_fire_damage.start()
			await get_tree().create_timer(FIRE_DUR).timeout
			timer_fire_damage.stop()
			area_fire.monitoring = false
			area_fire.visible = false	
		SPELLS.HEAL: pass
		SPELLS.SACRIFICE: pass
		SPELLS.LIGHTNING: 
			var new_lightning = area_lightning.duplicate()
			new_lightning.top_level = true
			add_child(new_lightning)
			new_lightning.global_transform = global_transform
			new_lightning.body_entered.connect(on_lightning_entered)
			new_lightning.monitoring = true
			new_lightning.visible = true
			await blink_lightning(new_lightning)
			if not is_instance_valid(new_lightning):
				return
			new_lightning.visible = false
			new_lightning.monitoring = false
			await get_tree().create_timer(LIGHTNING_CLEANUP_TIME).timeout
			if is_instance_valid(new_lightning):
				new_lightning.queue_free()

func blink_lightning(lightning: Area3D) -> void:
	for i in LIGHTNING_BLINKS:
		var decay = float(i) / float(LIGHTNING_BLINKS)
		lightning.visible = true
		await get_tree().create_timer(
			LIGHTNING_BLINK_TIME * lerpf(1.0, 0.3, decay) * randf_range(0.5, 1.0)
		).timeout
		if not is_instance_valid(lightning):
			return
		lightning.visible = false
		await get_tree().create_timer(LIGHTNING_BLINK_TIME * (0.3 + decay)).timeout
		if not is_instance_valid(lightning):
			return

func deal_fire_tick():
	for body in area_fire.get_overlapping_bodies():
		if body is Enemy:
			body.health_system.damage(FIRE_TICK_DAMAGE)

func on_lightning_entered(body: Node3D):
	if body is Enemy:
		body.health_system.damage(randi_range(LIGHTNING_DAMAGE_MIN, LIGHTNING_DAMAGE_MAX))
