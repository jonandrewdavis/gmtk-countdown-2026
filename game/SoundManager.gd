extends Node

const MUSIC_TITLE: AudioStream = preload("res://assets/sound/Songs/New Title Screen.wav")
const MUSIC_INTRO: AudioStream = preload("res://assets/sound/Songs/Intro.wav")
const MUSIC_COMBAT: AudioStream = preload("res://assets/sound/Songs/Combat.wav")

const SFX_FOOTSTEPS: Array[AudioStream] = [
	preload("uid://dwceofsyei3cy"),
	preload("uid://ckxlaycn2memq"),
	preload("uid://bo7c6hq4ha48r"),
]

const FIRE_SPELL = preload("res://assets/sound/Sounds/Spell Sounds/Fire Spell.wav")
const ELECTRIC_SPELL = preload("res://assets/sound/Sounds/Spell Sounds/Electric Spell.wav")
const ICE_SPELL = preload("res://assets/sound/Sounds/Spell Sounds/Ice Spell.wav")
const PROTECTION_SPELL = preload("res://assets/sound/Sounds/Spell Sounds/Protection Spell.wav")

const SFX_DAMAGE_TICK: AudioStream = preload("res://assets/sound/Sounds/Misc/click.mp3")

const BUS_BGM := &"BGM"
const BUS_SFX := &"SFX"

const MUSIC_VOLUME_DB := -8.0
const MUSIC_SILENT_DB := -45.0
const MUSIC_FADE_TIME := 2.5
const SFX_VOLUME_DB := -6.0
const SFX_PLAYER_COUNT := 6

var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var music_player_active: AudioStreamPlayer
var music_stream_playing: AudioStream = null
var music_tween: Tween
var sfx_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	music_player_a = _make_player("MusicPlayerA", BUS_BGM, MUSIC_SILENT_DB)
	music_player_b = _make_player("MusicPlayerB", BUS_BGM, MUSIC_SILENT_DB)
	music_player_active = music_player_a

	for i in SFX_PLAYER_COUNT:
		sfx_players.append(_make_player("SfxPlayer%d" % i, BUS_SFX, SFX_VOLUME_DB))

	Global.signal_footstep.connect(play_footstep)
	Global.signal_enemy_damaged.connect(play_damage_tick)
	Global.signal_spell_start.connect(play_spell_sound)

func _make_player(player_name: String, bus: StringName, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus
	player.volume_db = volume_db
	add_child(player)
	return player

func crossfade_bgm(stream: AudioStream, fade_time := MUSIC_FADE_TIME) -> void:
	if stream == music_stream_playing:
		return

	music_stream_playing = stream
	var previous := music_player_active
	var next := music_player_b if music_player_active == music_player_a else music_player_a
	music_player_active = next

	if music_tween:
		music_tween.kill()
	music_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)

	if stream:
		next.stream = stream
		next.volume_db = MUSIC_SILENT_DB
		next.play()
		music_tween.tween_property(next, "volume_db", MUSIC_VOLUME_DB, fade_time)

	if previous.playing:
		music_tween.tween_property(previous, "volume_db", MUSIC_SILENT_DB, fade_time)
		music_tween.chain().tween_callback(previous.stop)

func play_sfx(stream: AudioStream, volume_db := SFX_VOLUME_DB, pitch_scale := 1.0) -> void:
	if stream == null:
		return

	var free_player: AudioStreamPlayer = sfx_players[0]
	for sfx_player in sfx_players:
		if not sfx_player.playing:
			free_player = sfx_player
			break

	free_player.stream = stream
	free_player.volume_db = volume_db
	free_player.pitch_scale = pitch_scale
	free_player.play()

func play_footstep() -> void:
	play_sfx(SFX_FOOTSTEPS.pick_random(), SFX_VOLUME_DB, randf_range(0.9, 1.1))

func play_spell_sound(spell: SpellSystem.SPELLS) -> void:
	match spell:
		SpellSystem.SPELLS.ICE: play_sfx(ICE_SPELL)
		SpellSystem.SPELLS.FIRE: play_sfx(FIRE_SPELL)
		SpellSystem.SPELLS.LIGHTNING: play_sfx(ELECTRIC_SPELL)
		SpellSystem.SPELLS.HEAL: play_sfx(PROTECTION_SPELL)
		SpellSystem.SPELLS.SACRIFICE: play_sfx(PROTECTION_SPELL)

func play_damage_tick(_damage: int = 0):
	play_sfx(SFX_DAMAGE_TICK, SFX_VOLUME_DB, randf_range(0.9, 1.1))
