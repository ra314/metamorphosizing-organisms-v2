extends Node

var id
var oname
var ability
var ability_description
var mana_type
var mana_enum
var mana_to_activate
var player
var game

var is_evolved = false
var data = null
var mana = 0

func save():
	pass

func get_organism_id(mon_name):
	for i in range(len(Dex.data)):
		if Dex.data[i]["base_organism"]["name"] == mon_name:
			return i
		if Dex.data[i]["evolved_organism"]["name"] == mon_name:
			return i
	print("Mon is not found")
	assert(false)

func create_base_mon(mon_name, _player):
	var _id = get_organism_id(mon_name)
	var mon_data = Dex.data[_id]["base_organism"]
	return init(_id, mon_name, mon_data["ability"], mon_data["ability_description"], \
		Dex.data[_id]["mana_type"], Dex.data[_id]["mana_to_activate"], _player)

func init(_id, _oname, _ability, _ability_description, _mana_type, _mana_to_activate, _player):
	self.id = _id
	self.oname = _oname
	self.ability = _ability
	self.ability_description = _ability_description
	self.mana_type = _mana_type
	mana_enum = ManaTex.enum(_mana_type)
	self.mana_to_activate = _mana_to_activate
	self.player = _player
	$Mana_Icon.texture = ManaTex.dict[_mana_type]
	$Mana_Bar.max_value = _mana_to_activate
	update_ui()
	return self

func evolve():
	if not is_evolved:
		oname = data[id]['evolved_organism']['name']
		ability = data[id]['evolved_organism']['ability_name']
		ability_description = data[id]['evolved_organism']['ability_description']
		data.close()

func change_mana(delta):
	# Clamping mana
	var prev_mana = mana
	mana = clamp(mana + delta, 0, mana_to_activate)
	update_ui()
	# Returning the amount change in mana
	return abs(mana - prev_mana)

func update_ui():
	$Mana_Bar.value = mana
	$Mana_Text.text = str(mana) + "/" + str(mana_to_activate)
	
func show_berry_actions():
	$Berry_Control.show()
	if is_evolved:
		$Berry_Control/Boost_Text.show()
	else:
		$Berry_Control/Evolve_Text.show()
		
func hide_berry_actions():
	$Berry_Control.hide()

####### Abilities
func do_ability():
	if mana == mana_to_activate:
		call(ability)

func sear():
	game.next_player.change_HP(20)
	game.grid.force_grid_match(-1,1,1)

func desear():
	game.next_player.change_HP(25)
	game.grid.force_grid_match(-1,1,2)

func splash():
	game.next_player.change_HP(10)
	game.grid.force_grid_match(1,1,2)

func crash():
	game.next_player.change_HP(20)
	game.grid.force_grid_match(1,1,3)

func shock():
	game.next_player.change_HP(15)
	for organism in game.next_player.organisms:
		organism.change_mana(-2)

func awe():
	game.next_player.change_HP(20)
	for organism in game.next_player.organisms:
		organism.change_mana(-3)

func perseverance():
	pass
	# TODO heal 5 and deal 5 for 3 turns at the end of turn

func fortitude():
	pass
	# TODO heal 10 and deal 10 for 2 turns at the end of turn

func ovation():
	game.next_player.change_HP(10)
	# TODO grant extra move in the next turn

func encore():
	game.next_player.change_HP(15)
	# TODO grant extra move in the next 2 turns

####### Abilities

# The organisms are to be stored in a list
# Each item in the list is a dictionary of the structure shown below.
# base_organism:
	# name: <organism name>
	# ability: <ability name>
	# ability_description: <ability description>
# evolved_organism:
	# name: <evolved organism name>:
	# ability: <evolved ability name>
	# ability_description: <evolved ability description>
