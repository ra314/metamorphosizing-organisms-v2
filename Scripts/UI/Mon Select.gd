extends Control
var selected_mons = []
const selection_text = "Selected: "
onready var _root: Main = get_tree().get_root().get_node("Main")
onready var Organism = load("res://Scenes/Levels/Level Components/Organism.tscn")
var UIgrid = load("res://Scripts/UI_Grid.gd").new()

# Called when the node enters the scene tree for the first time.
func _ready():
	UIgrid.init(512*0.5,512*0.5,6,Vector2(256, 256)*0.5+Vector2(200, 200))
	# Adding buttons to select organism
	for mon_data in Dex.data:
		var mon = Organism.instance().create_base_mon(mon_data["base_organism"]["name"])
		mon.scale = Vector2(0.408,0.408)
		mon.get_node("Sprite").texture_hover = load("res://Assets/Organism/Organism_Game_Field_Placeholder_Mask.png")
		UIgrid.add_object(mon)
		mon.get_node("Sprite").connect("button_down", self, "add_selection", [mon.oname])
		add_child(mon)
	
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

func next():
	rpc("create_player", selected_mons[0], selected_mons[1], _root.player_index)
	if null in _root.players_for_level_main:
		if _root.online_game:
			_load_scene("UI/Waiting")
		else:
			_root.player_index = 1
			$CenterContainer/VBoxContainer/Selection_Label.text = selection_text
			selected_mons = []
	else:
		_root.rpc("load_level", "Levels/Level Main", _root.world_str)

# Here we just store the inputs, we create the players and mons in level main
remotesync func create_player(mon1_name, mon2_name, player_index):
	_root.players_for_level_main[player_index] = [mon1_name, mon2_name]

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

func _load_scene(scene_str):	
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
