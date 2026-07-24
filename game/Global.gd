extends Node

const GRID_SIZE = 1

enum SPELLS {
	ICE,
	FIRE,
	HEAL,
	SACRIFICE
}


signal signal_spell_start(SPELLS)
