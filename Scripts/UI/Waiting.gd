extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 	
	$TextureButton.connect("button_down", self, "back")

func back():
	# Removing the current scene from history
	_root.scene_manager.loaded_scene_history.pop_back()
	# Removing the previous scene from history since we're going to load it again
	var prev_scene_str = _root.scene_manager.loaded_scene_history.pop_back()
	# Reverting side effects
	_root.players = {}
	_root.peer.close_connection()
	_root.get_tree().network_peer = null
	# Loading the previous scene
	var scene = _root.scene_manager._load_scene(prev_scene_str)
	_root.scene_manager._replace_scene(scene)

# I'm putting this function here so that when you go to the waiting screen
# from mon select, the remotesync call of create_player still executes.
# Here we just store the inputs, we create the players and mons in level main
remotesync func create_player(mon1_name, mon2_name, player_index):
	_root.players_for_level_main[player_index] = [mon1_name, mon2_name]
