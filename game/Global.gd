extends Node

const GRID_SIZE = 1

enum SPELLS {
	ICE,
	FIRE,
	HEAL,
	SACRIFICE
}

func _enter_tree() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)

signal signal_spell_start(SPELLS)
signal signal_enemy_damaged(amount: int)
signal signal_footstep
signal signal_enemy_target_changed
