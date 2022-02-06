extends Control
var selected_mons = []
const selection_text = "Selected: "
onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready():
	# Adding buttons to select organism
	var data = File.new()
	var data_location = "res://data.save"
	data.open(data_location, File.READ)
	data = JSON.parse(data.get_as_text()).result
	for mon in data:
		var button = Button.new()
		button.text = mon["base_organism"]["name"]
		button.connect("button_down", self, "add_selection", [button.text])
		$CenterContainer/VBoxContainer/GridContainer.add_child(button)
	data.close()
	
	# Label to display selected organisms
	$CenterContainer/VBoxContainer/Selection_Label.text = selection_text
	$CenterContainer/VBoxContainer/Next.connect("button_down", self, "next")
	
	$TextureButton.connect("button_down", self, "back")

func add_selection(mon):
	# If there's already 2 selected organisms, 
	# pop the last one and insert the new one at the front
	if len(selected_mons) == 2:
		selected_mons.pop_back()
	selected_mons.push_front(mon)
	
	# Changing selection text
	var final_text
	if len(selected_mons) == 1:
		final_text = selection_text + selected_mons[0]
	if len(selected_mons) == 2:
		final_text = selection_text + selected_mons[0] + ", " + selected_mons[1]
	$CenterContainer/VBoxContainer/Selection_Label.text = final_text

const Player = preload("res://Scenes/Levels/Level Components/Player.tscn")
func next():
	var new_player = Player.new().init()
	if not ('player1' in _root.players):
		

func back():
	# Removing the current scene from history
	_root.scene_manager.loaded_scene_history.pop_back()
	# Removing the previous scene from history since we're going to load it again
	var prev_scene_str = _root.scene_manager.loaded_scene_history.pop_back()
	# Reverting side effects
	_root.online_game = false
	# Loading the previous scene
	var scene = _root.scene_manager._load_scene(prev_scene_str)
	_root.scene_manager._replace_scene(scene)
