extends VBoxContainer

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 
	$Local/Button.connect("button_down", self, "_load_scene", ["UI/Level Select"])
	$Online/Button.connect("button_down", self, "_load_scene",  ["UI/Host Guest"])
	
	# Still need online multiplayer to be on so that the rpc calls can execute
	# The RPC target is still local, but it won't execute unless online multiplayer is on
	$Local/Button.connect("button_down", _root, "host")

func _load_scene(scene_str):
	# Dirty workaround to check if the pressed button was for the online gaming component
	if scene_str == "UI/Host Guest":
		_root.online_game = true
	
	if _root.online_game:
		var scene = _root.scene_manager._load_scene(scene_str)
		_root.scene_manager._replace_scene(scene)
	else:
		_root.all_players_connected()
