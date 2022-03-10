extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connections for level select
	var next_scene = "UI/Mon Select"
	var container = $CenterContainer/VBoxContainer/
	container.get_node("C3/H1/V1/Stadium").connect("button_down", self, "_load_scene", [next_scene, "Stadium"])
	container.get_node("C3/H1/V2/Forest Valley").connect("button_down", self, "_load_scene", [next_scene, "Forest Valley"])
	container.get_node("C3/H1/V3/Abandoned Town").connect("button_down", self, "_load_scene", [next_scene, "Abandoned Town"])
	container.get_node("C4/H1/V1/Tranquil Falls").connect("button_down", self, "_load_scene", [next_scene, "Tranquil Falls"])
	container.get_node("C4/H1/V2/Lava Caverns").connect("button_down", self, "_load_scene", [next_scene, "Lava Caverns"])
	container.get_node("C4/H1/Random").connect("button_down", self, "_load_scene", [next_scene, ""])
	$TextureButton.connect("button_down", self, "back")

func back():
	# Removing the current scene from history
	_root.scene_manager.loaded_scene_history.pop_back()
	# Removing the previous scene from history since we're going to load it again
	var prev_scene_str = _root.scene_manager.loaded_scene_history.pop_back()
	# Reverting side effects
	if _root.online_game:
		_root.player_name = ""
		_root.players = {}
		_root.peer.close_connection()
		_root.get_tree().network_peer = null
	# Loading the previous scene
	var scene = _root.scene_manager._load_scene(prev_scene_str)
	_root.scene_manager._replace_scene(scene)

func _load_scene(scene_str, world_str):
	var worlds = ["Stadium", "Forest Valley", "Abandoned Town", "Tranquil Falls", "Lava Caverns"]

	# Pick the random world if the world_str is empty
	if world_str == "":
		world_str = _root.select_random(worlds)
	
	_root.rpc("change_to_select_mon_scene", scene_str, world_str)
	# Remote Procedure Call if the game is online
#	if _root.online_game:
#		_root.rpc("change_to_select_mon_scene", scene_str, world_str)
#	# Regular function call for offline game
#	else:
#		_root.change_to_select_mon_scene(scene_str, world_str)
