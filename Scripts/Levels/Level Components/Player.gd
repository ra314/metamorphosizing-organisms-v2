extends Node2D

var organisms
var pname
var game

var max_HP = 80
var curr_HP = max_HP
var max_berries = 4
var berries = 0

func init(_pname):
	self.organisms = [$Organism1, $Organism2]
	for organism in organisms:
		add_child(organism)
		organism.connect("evolving_end", self, "consume_all_berries")
	self.pname = _pname
	return self

func consume_all_berries():
	change_berries(-berries)

func change_HP(delta):
	# Clamping health
	# The max of current and max hp is done in the case of the start where p2 has 5 extra HP
	curr_HP = clamp(curr_HP + delta, 0, max(max_HP, curr_HP))
	update_ui()

func change_berries(delta):
	# Clamping berries
	var prev_berries = berries
	berries = clamp(berries + delta, 0, max_berries)
	update_ui()
	# Returning the amount change in berries
	return abs(berries - prev_berries)
	
func update_ui(hide_berries=true):
	$Health_Control/Health/Text.text = str(curr_HP)
	$Berry_Control/Berry/Text.text = str(berries) + "/" + str(max_berries)
	if berries == max_berries and not hide_berries:
		for organism in organisms:
			organism.show_berry_actions()
	else:
		for organism in organisms:
			organism.hide_berry_actions()
