extends Node

const GRID_SIZE = 1

var spell_system: SpellSystem

func _enter_tree() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)

# Player
signal signal_spell_start(SPELLS)
signal signal_footstep
signal signal_hurt

# Enemy
signal signal_enemy_damaged(amount: int)
signal signal_enemy_target_changed
