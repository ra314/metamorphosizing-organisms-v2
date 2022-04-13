extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")
var stage_name_to_node = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connections for level select
	var next_scene = "UI/Mon Select"
	var container = $CenterContainer/VBoxContainer/
	stage_name_to_node["Stadium"] = container.get_node("C3/H1/V1")
	stage_name_to_node["Forest Valley"] = container.get_node("C3/H1/V2")
	stage_name_to_node["Abandoned Town"] = container.get_node("C3/H1/V3")
	stage_name_to_node["Tranquil Falls"] = container.get_node("C4/H1/V1")
	stage_name_to_node["Lava Caverns"] = container.get_node("C4/H1/V2")
	stage_name_to_node["Random"] = container.get_node("C4/H1")
	stage_name_to_node["Stadium"].get_node("Button")\
		.connect("button_down", self, "_load_scene", [next_scene, "Stadium"])
	stage_name_to_node["Forest Valley"].get_node("Button")\
		.connect("button_down", self, "_load_scene", [next_scene, "Forest Valley"])
	stage_name_to_node["Abandoned Town"].get_node("Button")\
		.connect("button_down", self, "_load_scene", [next_scene, "Abandoned Town"])
	stage_name_to_node["Tranquil Falls"].get_node("Button")\
		.connect("button_down", self, "_load_scene", [next_scene, "Tranquil Falls"])
	stage_name_to_node["Lava Caverns"].get_node("Button")\
		.connect("button_down", self, "_load_scene", [next_scene, "Lava Caverns"])
	stage_name_to_node["Random"].get_node("Button")\
		.connect("button_down", self, "_load_scene", [next_scene, ""])
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
		world_str = Utils.select_random(worlds)
	var world_details = stage_name_to_node[world_str].get_node("Label").text
	
	_root.rpc("change_to_select_mon_scene", scene_str, world_str, world_details)
	# Remote Procedure Call if the game is online
#	if _root.online_game:
#		_root.rpc("change_to_select_mon_scene", scene_str, world_str)
#	# Regular function call for offline game
#	else:
#		_root.change_to_select_mon_scene(scene_str, world_str)
