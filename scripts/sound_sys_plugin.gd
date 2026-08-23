@tool
extends EditorPlugin

const PLUGIN_NAME = "SoundSys"
const AUTOLOAD_NAME = "SoundSys"
const AUTOLOAD_PATH = "res://addons/sound_system/scenes/sound_sys.tscn"

func _enter_tree():

	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	print("SoundSys Plugin: Autoload '%s' added." % AUTOLOAD_NAME)



func _exit_tree():

	remove_autoload_singleton(AUTOLOAD_NAME)
	print("SoundSys Plugin: Autoload '%s' removed." % AUTOLOAD_NAME)
