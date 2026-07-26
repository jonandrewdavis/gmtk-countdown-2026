extends Node3D
class_name SpellSystem

# TODO: spell resource:
# cooldown
# duration
# mesh?
# overlay?
# Difficult because they can have multiple or varying effects.

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

func get_spell_cooldown(SPELL):
	return SPELL_COOLDOWNS.get(SPELLS.keys()[SPELL])

func _ready() -> void:
	Global.signal_spell_start.connect(spell_start)

func spell_start(spell: SPELLS):
	match spell:
		SPELLS.ICE:  pass
		SPELLS.FIRE: pass
		SPELLS.HEAL: pass
		SPELLS.SACRIFICE: pass
		SPELLS.LIGHTNING: pass
