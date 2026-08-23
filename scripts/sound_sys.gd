@tool
extends Node





























@warning_ignore("unused_signal")
signal play_sfx_requested(sfx_key: String, bus: String, manager_node: Node)




@warning_ignore("unused_signal")
signal play_music_requested(music_key: String, manager_node: Node)



@warning_ignore("unused_signal")
signal music_track_changed(music_key: String)





@warning_ignore("unused_signal")
signal volume_changed(bus_name: String, linear_volume: float)



@warning_ignore("unused_signal")
signal request_audio_start()


const SFX_BUS_NAME = "SFX"
const MUSIC_BUS_NAME = "Music"


@export var audio_manifest: AudioManifest


var _sfx_library: Dictionary = {}
var _music_library: Dictionary = {}


var _music_playlist_keys: Array = []

var _current_playlist_key: String = ""


@export var _sfx_player_count = 15

var _sfx_players: Array[AudioStreamPlayer] = []

@onready var _music_player: AudioStreamPlayer = $MusicPlayer

@onready var _music_change_timer: Timer = $MusicChangeTimer


func _ready():

	_music_player.bus = MUSIC_BUS_NAME
	_music_player.finished.connect(_on_music_finished)


	play_sfx_requested.connect(_on_play_sfx_requested)
	play_music_requested.connect(_on_play_music_requested)


	SoundSys.request_audio_start.connect(_on_request_audio_start)




func _on_request_audio_start():
	_setup_audio_buses()
	_load_audio_from_manifest()
	_select_and_play_random_playlist()
	_music_change_timer.start()



func _setup_audio_buses():

	if AudioServer.get_bus_index(MUSIC_BUS_NAME) == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		var music_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_idx, MUSIC_BUS_NAME)
		AudioServer.set_bus_send(music_bus_idx, "Master")
		print("SoundSys: Created Music audio bus.")


	if AudioServer.get_bus_index(SFX_BUS_NAME) == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		var sfx_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_idx, SFX_BUS_NAME)
		AudioServer.set_bus_send(sfx_bus_idx, "Master")
		print("SoundSys: Created SFX audio bus.")




func _load_audio_from_manifest():
	if not audio_manifest:
		printerr("SoundSys: AudioManifest not assigned. Please generate it in the editor.")
		return

	_sfx_library = audio_manifest.sfx_data
	_music_library = audio_manifest.music_data
	_music_playlist_keys = _music_library.keys()

	print("SoundSys: Loaded audio from manifest. %d music playlists and %d SFX categories found." % [_music_playlist_keys.size(), _sfx_library.size()])



	var sfx_player_node = get_node_or_null("SFXPlayer")
	if sfx_player_node:
		for child in sfx_player_node.get_children():
			if child is AudioStreamPlayer:
				child.bus = SFX_BUS_NAME
				child.finished.connect(Callable(self, "_on_sfx_player_finished").bind(child))
				_sfx_players.append(child)
	else:


		print("SoundSys: SFXPlayer Node not found in scene. Creating %d AudioStreamPlayers dynamically." % _sfx_player_count)
		for i in range(_sfx_player_count):
			var sfx_player = AudioStreamPlayer.new()
			sfx_player.name = "SFXPlayer_%d" % i
			sfx_player.bus = SFX_BUS_NAME
			sfx_player.finished.connect(Callable(self, "_on_sfx_player_finished").bind(sfx_player))
			add_child(sfx_player)
			_sfx_players.append(sfx_player)









func _on_play_sfx_requested(sfx_key: String, bus: String = SFX_BUS_NAME, manager_node: Node = self):
	if not _sfx_library.has(sfx_key):
		printerr("SoundSys: SFX key not found in library: '%s'" % sfx_key)
		return

	var sfx_uids = _sfx_library[sfx_key]
	if sfx_uids.is_empty():
		printerr("SoundSys: SFX category '%s' is empty." % sfx_key)
		return


	var random_uid_str = sfx_uids.pick_random()
	var uid_int = random_uid_str.replace("uid://", "").to_int()
	var resource_path = ResourceUID.get_id_path(uid_int)

	if resource_path.is_empty():
		printerr("SoundSys: Failed to get resource path for SFX UID: '%s'" % random_uid_str)
		return


	var sound_stream = load(resource_path)

	if sound_stream == null:
		printerr("SoundSys: Failed to load SFX stream from path: '%s' (UID: '%s')" % [resource_path, random_uid_str])
		return


	for player in _sfx_players:
		if not player.playing:
			player.stream = sound_stream
			player.bus = bus
			player.play()
			return







func _on_play_music_requested(music_key: String, manager_node: Node = self):
	if not _music_library.has(music_key):
		printerr("SoundSys: Music key not found in library: '%s'" % music_key)
		return

	var music_uids = _music_library[music_key]
	if music_uids.is_empty():
		printerr("SoundSys: Music category '%s' is empty." % music_key)
		return


	var random_uid_str = music_uids.pick_random()
	var uid_int = random_uid_str.replace("uid://", "").to_int()
	var resource_path = ResourceUID.get_id_path(uid_int)

	if resource_path.is_empty():
		printerr("SoundSys: Failed to get resource path for UID: '%s'" % random_uid_str)
		return


	var music_stream = load(resource_path)

	if music_stream == null:
		printerr("SoundSys: Failed to load music stream from path: '%s' (UID: '%s')" % [resource_path, random_uid_str])
		return


	if _music_player.stream == music_stream and _music_player.playing:
		return

	_music_player.stream = music_stream
	_music_player.play()
	music_track_changed.emit(music_key)

func stop_music():
	_music_player.stop()




func _select_and_play_random_playlist():
	if _music_playlist_keys.is_empty():
		printerr("SoundSys: No music playlists found to play.")
		return

	_current_playlist_key = _music_playlist_keys.pick_random()
	play_music_requested.emit(_current_playlist_key)








func apply_volume_to_bus(bus_name: String, linear_volume: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var db_volume = linear_to_db(linear_volume) if linear_volume > 0 else -80.0
		AudioServer.set_bus_volume_db(bus_index, db_volume)
		volume_changed.emit(bus_name, linear_volume)
	else:
		printerr("SoundSys: Audio bus '%s' not found." % bus_name)





func _on_music_finished():
	_select_and_play_random_playlist()



func _on_music_change_timer_timeout():
	_select_and_play_random_playlist()




func _on_sfx_player_finished(player: AudioStreamPlayer):
	player.stream = null
