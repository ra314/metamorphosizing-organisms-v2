extends Node2D

var id
var oname
var ability
var ability_description
var mana_type
var mana_to_activate
var game

var is_evolved = false
var data = null
var mana = 0

func save():
	pass

func init(_id, _oname, _ability, _ability_description, _mana_type, _mana_to_activate, _game):
	self.id = _id
	self.oname = _oname
	self.ability = _ability
	self.ability_description = _ability_description
	self.mana_type = _mana_type
	self.mana_to_active = _mana_to_activate
	self.game = _game
	return self

func evolve():
	if not is_evolved:
		oname = data[id]['evolved_organism']['name']
		ability = data[id]['evolved_organism']['ability_name']
		ability_description = data[id]['evolved_organism']['ability_description']

func change_mana(delta):
	# Clamping mana
	var prev_mana = mana
	mana = clamp(mana + delta, 0, mana_to_activate)
	# Returning the amount change in mana
	return abs(mana - prev_mana)

func flare():
	game.next_player.change_HP(20)
	game.grid.force_grid_match([-1,1,1])

func flare_p():
	game.next_player.change_HP(25)
	game.grid.force_grid_match([-1,1,2])



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
