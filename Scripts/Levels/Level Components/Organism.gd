extends Node

var id
var oname
var ability
var ability_description
var mana_type
var mana_enum
var mana_to_activate
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

func create_base_mon(mon_name):
	var _id = get_organism_id(mon_name)
	var mon_data = Dex.data[_id]["base_organism"]
	return init(_id, mon_name, mon_data["ability"], mon_data["ability_description"], \
		Dex.data[_id]["mana_type"], Dex.data[_id]["mana_to_activate"])

func init(_id, _oname, _ability, _ability_description, _mana_type, _mana_to_activate):
	self.id = _id
	self.oname = _oname
	self.ability = _ability
	self.ability_description = _ability_description
	self.mana_type = _mana_type
	mana_enum = ManaTex.enum(_mana_type)
	self.mana_to_activate = _mana_to_activate
	$Mana_Icon.texture = ManaTex.dict[_mana_type]
	$Mana_Bar.max_value = _mana_to_activate
	update_ui()
	tween_mana(0, 0)
	return self

func _ready():
	$Berry_Control/Evolve_Text.connect("button_down", self, "evolve1")
	$Berry_Control/Boost_Text.connect("button_down", self, "boost1")

signal evolving_start
signal evolving_end
func evolve1():
	rpc("evolve2")
remotesync func evolve2():
	if is_evolved:
		return
	emit_signal("evolving_start")
	
	oname = Dex.data[id]['evolved_organism']['name']
	ability = Dex.data[id]['evolved_organism']['ability']
	ability_description = Dex.data[id]['evolved_organism']['ability_description']
	is_evolved = true
	
	emit_signal("evolving_end")

signal boosting
func boost1():
	rpc("boost2")
remotesync func boost2():
	emit_signal("boosting", self)
	
func flip_sprite():
	$Sprite.scale *= Vector2(-1, 1)

func change_mana(delta):
	# Clamping mana
	var prev_mana = mana
	mana = clamp(mana + delta, 0, mana_to_activate)
	update_ui()
	tween_mana(prev_mana, mana)
	# Returning the amount change in mana
	return abs(mana - prev_mana)

const animation_mana_speed = 1
func tween_mana(prev_mana, mana):
	$Tween.interpolate_property($Mana_Bar, "value", prev_mana, mana, animation_mana_speed, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.start()
	
func update_ui():
	# $Mana_Bar.value = mana
	$Mana_Text.text = str(mana) + "/" + str(mana_to_activate)
	
func show_berry_actions():
	$Berry_Control.show()
	if is_evolved:
		$Berry_Control/Boost_Text.show()
		$Berry_Control/Evolve_Text.hide()
	else:
		$Berry_Control/Boost_Text.hide()
		$Berry_Control/Evolve_Text.show()

func hide_berry_actions():
	$Berry_Control.hide()

####### Abilities
func do_ability():
	if mana == mana_to_activate:
		call(ability)
		mana = 0
		tween_mana(mana_to_activate, mana)
		update_ui()

func sear():
	game.next_player.change_HP(-20)
	game.grid.force_grid_match(-1,1,1)

func desear():
	game.next_player.change_HP(-25)
	game.grid.force_grid_match(-1,1,2)

func splash():
	game.next_player.change_HP(-10)
	game.grid.convert_tiles(ManaTex.enum("water"), 2)

func crash():
	game.next_player.change_HP(-20)
	game.grid.convert_tiles(ManaTex.enum("water"), 3)

func shock():
	game.next_player.change_HP(-15)
	for organism in game.next_player.organisms:
		organism.change_mana(-2)

func awe():
	game.next_player.change_HP(-20)
	for organism in game.next_player.organisms:
		organism.change_mana(-3)

func perseverance():
	game.register_repeated_action(self, "perseverance_mini", 3, null, "turn_end")

func perseverance_mini():
	game.next_player.change_HP(-5)
	game.curr_player.change_HP(5)

func fortitude():
	game.register_repeated_action(self, "fortitude_mini", 2, null, "turn_end")

func fortitude_mini():
	game.next_player.change_HP(-10)
	game.curr_player.change_HP(10)

func ovation():
	game.next_player.change_HP(-10)
	game.register_repeated_action(self, "ovation_mini", 1, null, "turn_start")

func ovation_mini():
	game.add_extra_move()

func encore():
	game.next_player.change_HP(-15)
	game.register_repeated_action(self, "encore_mini", 2, null, "turn_start")

func encore_mini():
	game.add_extra_move()
	
func mobilize():
	for organism in game.curr_player.organisms:
		if organism != self:
			organism.change_mana(2)

func reform():
	for organism in game.curr_player.organisms:
		if organism != self:
			organism.change_mana(3)

func headway():
	game.next_player.change_HP(-35)
	game.register_repeated_action(self, "headway_mini", 1, game.curr_player, "player_turn")

func headway_mini():
	game.remove_move()
	
func breakthrough():
	game.next_player.change_HP(-45)
	game.register_repeated_action(self, "headway_mini", 2, game.curr_player, "player_turn")

func reakthrough_mini():
	game.remove_move()

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
