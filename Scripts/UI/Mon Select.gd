extends Control
var selected_mons = []
const selection_text = "Selected: "

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
	
	# Label to display selected organisms
	$CenterContainer/VBoxContainer/Selection_Label.text = selection_text

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
	
