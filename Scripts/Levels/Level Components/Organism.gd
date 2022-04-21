extends Node

var id
var oname
var ability
var ability_description
var mana_type
var mana_enum

var game
var alignment

var is_evolved = false

var mana = 0
var mana_to_activate = 0
var extra_mana_to_activate = 0
func change_extra_mana_to_activate(delta):
	extra_mana_to_activate += delta
	$Mana_Bar.max_value = mana_to_activate + extra_mana_to_activate
	update_ui()

func is_full_of_mana():
	return mana == mana_to_activate + extra_mana_to_activate

var mana_absorption_blocked = false
func set_mana_absorption_blocked(boolean):
	mana_absorption_blocked = boolean
	if boolean:
		$Sprite.modulate = Color(1,0,0,1)
	else:
		$Sprite.modulate = Color(1,1,1,1)

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

func get_combined_ability_description():
	var mon_data = Dex.data[id]
	return  "(L1) " + mon_data["base_organism"]["ability_description"] + "\n" + \
			"(L2) " + mon_data["evolved_organism"]["ability_description"]

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
	
	$Mana_Bar.value = 0
	$Mana_Bar.tint_progress = ManaTex.colors[mana_type]
	return self

var button_down_timestamp
func record_button_down():
	button_down_timestamp = OS.get_ticks_msec()

signal long_press
signal short_press
func is_button_up_long_press():
	var curr_time = OS.get_ticks_msec()
	if curr_time - button_down_timestamp > 500:
		emit_signal("long_press", self)
	else:
		emit_signal("short_press")

func _ready():
	$Berry_Control/Evolve_Text.connect("button_down", self, "evolve1")
	$Berry_Control/Boost_Text.connect("button_down", self, "boost1")
	$Sprite.connect("button_down", self, "record_button_down")
	$Sprite.connect("button_up", self, "is_button_up_long_press")

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
	$Evolution_Stage.text = "L2"
	is_evolved = true
	
	emit_signal("evolving_end")

signal boost
func boost1():
	rpc("boost2")
remotesync func boost2():
	emit_signal("boost", self)

func flip_sprite():
	$Sprite.flip_h = !$Sprite.flip_h

const MANA_ICON_SCALE = Vector2(1,1)*0.483
func change_mana(delta):
	# Prevent the absorption of mana if blocked, but allow the draining of mana
	if mana_absorption_blocked:
		if delta > 0:
			# Returning the amount change in mana
			return 0
	
	# Clamping mana
	var prev_mana = mana
	mana = clamp(mana + delta, 0, mana_to_activate)
	
	# Animation for the mana icon
	$Mana_Icon.scale = MANA_ICON_SCALE
	$Mana_Icon.modulate = Color.white
	
	if delta > 0:
		$Tween.interpolate_property($Mana_Icon, "scale", $Mana_Icon.scale * 1.5, $Mana_Icon.scale, 1, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		$Tween.interpolate_property($Mana_Icon, "modulate", Color.green, $Mana_Icon.modulate, 1, Tween.TRANS_BACK, Tween.EASE_OUT)
	elif delta < 0:
		$Tween.interpolate_property($Mana_Icon, "scale", $Mana_Icon.scale * 0.5, $Mana_Icon.scale, 1, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		$Tween.interpolate_property($Mana_Icon, "modulate", Color.red, $Mana_Icon.modulate, 1, Tween.TRANS_BACK, Tween.EASE_OUT)
	$Tween.start()
	
	update_ui()
	tween_mana(prev_mana, mana)
	# Returning the amount change in mana
	return abs(mana - prev_mana)

const animation_mana_speed = 1
func tween_mana(prev_mana, mana):
	$Tween.interpolate_property($Mana_Bar, "value", prev_mana, mana, animation_mana_speed, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.start()
	
func update_ui():
	$Mana_Bar.value = mana
	$Mana_Text.text = str(mana) + "/" + str(mana_to_activate + extra_mana_to_activate)
	
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
var damage_to_take_from_activating_ability = 0
signal doing_ability
signal doing_mini_ability
func do_ability():
	if mana == mana_to_activate:
		change_mana(-mana_to_activate)
		emit_signal("doing_ability")
		call(ability)
		if damage_to_take_from_activating_ability > 0:
			game.curr_player.change_HP(-damage_to_take_from_activating_ability)
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
	game.next_player.change_HP(-10)
	for organism in game.next_player.organisms:
		organism.change_mana(-2)

func awe():
	game.next_player.change_HP(-15)
	for organism in game.next_player.organisms:
		organism.change_mana(-3)

# NOTE: The return values for the mini abilities indiciate whether or not the ability was activated.
# For example if the retval is false that means level_main shouldn't decrement the number of time
# that the mini ability is called.

func perseverance():
	var args = {'object': self, 'action': 'perseverance_mini',
				'num_times': 3, 'action_type': 'turn_end'}
	game.register_repeated_action(args)

func perseverance_mini(player):
	emit_signal("doing_mini_ability")
	player.change_HP(5)
	game.get_other_player(player).change_HP(-5)
	return true

func fortitude():
	var args = {'object': self, 'action': 'fortitude_mini',
				'num_times': 2, 'action_type': 'turn_end'}
	game.register_repeated_action(args)

func fortitude_mini(player):
	emit_signal("doing_mini_ability")
	player.change_HP(10)
	game.get_other_player(player).change_HP(-10)
	return true

func ovation():
	game.next_player.change_HP(-10)
	var args = {'object': self, 'action': 'ovation_mini',
				'num_times': 1, 'action_type': 'turn_start'}
	game.register_repeated_action(args)

func ovation_mini(player):
	if game.curr_player == player:
		emit_signal("doing_mini_ability")
		game.add_extra_move(null)
		return true
	return false

func encore():
	game.next_player.change_HP(-15)
	var args = {'object': self, 'action': 'encore_mini',
				'num_times': 2, 'action_type': 'turn_start'}
	game.register_repeated_action(args)

func encore_mini(player):
	if game.curr_player == player:
		emit_signal("doing_mini_ability")
		game.add_extra_move(null)
		return true
	return false
	
func mobilize():
	game.next_player.change_HP(-10)
	for organism in game.curr_player.organisms:
		if organism != self:
			organism.change_mana(2)

func reform():
	game.next_player.change_HP(-15)
	for organism in game.curr_player.organisms:
		if organism != self:
			organism.change_mana(3)

func headway():
	game.next_player.change_HP(-30)
	var args = {'object': self, 'action': 'headway_mini',
				'num_times': 2, 'action_type': 'turn_start'}
	game.register_repeated_action(args)

func headway_mini(player):
	if game.curr_player == player:
		emit_signal("doing_mini_ability")
		game.remove_move()
		return true
	return false
	
func breakthrough():
	game.next_player.change_HP(-40)
	var args = {'object': self, 'action': 'breakthrough_mini',
				'num_times': 2, 'action_type': 'turn_start'}
	game.register_repeated_action(args)

func breakthrough_mini(player):
	if game.curr_player == player:
		emit_signal("doing_mini_ability")
		game.remove_move()
		return true
	return false
	
func A025():
	game.next_player.change_HP(-10)
	var args = {'object': self, 'action': 'A025_mini',
				'num_times': 2, 'action_type': 'turn_start'}
	game.register_repeated_action(args)

func A025_mini(player):
	if game.curr_player == player:
		emit_signal("doing_mini_ability")
		player.change_berries(1)
		return true
	return false
	
func A026():
	game.next_player.change_HP(-20)
	var args = {'object': self, 'action': 'A026_mini',
				'num_times': 3, 'action_type': 'turn_start'}
	game.register_repeated_action(args)

func A026_mini(player):
	if game.curr_player == player:
		emit_signal("doing_mini_ability")
		player.change_berries(1)
		return true
	return false
		
func A027():
	game.next_player.change_HP(-10)
	game.grid.force_grid_match(1, 1, 3)
	# match 3 tiles
	var args = {'object': self, 'action': 'A027_mini',
				'num_times': 1, 'action_type': 'turn_start'}
	game.register_repeated_action(args)

func A027_mini(player):
	if game.get_other_player(player) == game.curr_player:
		emit_signal("doing_mini_ability")
		game.remove_move()
		return true
	return false
		
func A028():
	game.next_player.change_HP(-20)
	game.grid.force_grid_match(1, 1, 6)
	var args = {'object': self, 'action': 'A028_mini',
				'num_times': 1, 'action_type': 'turn_start'}
	game.register_repeated_action(args)

func A028_mini(player):
	if game.get_other_player(player) == game.curr_player:
		emit_signal("doing_mini_ability")
		game.remove_move()
		return true
	return false

var A29or30 = []
func A029():
	game.next_player.change_HP(-5)
	var target_org = Utils.select_random_or_remaining(A29or30, game.next_player.organisms)
	if target_org == null:
		var message = "No targets were found for A029."
		game._root.create_notification(message, 10, alignment)
	
	target_org.set_mana_absorption_blocked(true)
	A29or30.append(target_org)
	var message = target_org.oname + " was afflicted with A029"
	game._root.create_notification(message, 10, target_org.alignment)
	
	var args = {'object': self, 'action': 'A029_mini',
				'num_times': 2, 'action_type': 'move_start', 'cleanup': 'A029_cleanup'}
	game.register_repeated_action(args)

func A029_mini(player):
	if game.get_other_player(player) == game.curr_player:
		return true
	return false

func A029_cleanup(player):
	var target_org = A29or30.pop_front()
	target_org.set_mana_absorption_blocked(false)
	var message = target_org.oname + " was cured of A029"
	game._root.create_notification(message, 10, target_org.alignment)

func A030():
	game.next_player.change_HP(-15)
	var target_org = Utils.select_random_or_remaining(A29or30, game.next_player.organisms)
	if target_org == null:
		var message = "No targets were found for A030."
		game._root.create_notification(message, 10, alignment)
	
	target_org.set_mana_absorption_blocked(true)
	A29or30.append(target_org)
	var message = target_org.oname + " was afflicted with A030"
	game._root.create_notification(message, 10, alignment)
	
	var args = {'object': self, 'action': 'A030_mini',
				'num_times': 2, 'action_type': 'move_start', 'cleanup': 'A030_cleanup'}
	game.register_repeated_action(args)

func A030_mini(player):
	if game.get_other_player(player) == game.curr_player:
		return true
	return false

func A030_cleanup(player):
	var target_org = A29or30.pop_front()
	target_org.set_mana_absorption_blocked(false)
	var message = target_org.oname + " was cured of A030"
	game._root.create_notification(message, 10, target_org.alignment)

func A031():
	game.next_player.change_HP(-10)
	var args = {'object': self, 'action': 'A031_mini',
				'num_times': 2, 'action_type': 'turn_start', 'cleanup': 'A031_cleanup'}
	game.register_repeated_action(args)

func A031_mini(player):
	if game.get_other_player(player) == game.curr_player:
		emit_signal("doing_mini_ability")
		for organism in game.curr_player.organisms:
			# Max is used here since it is possible that A032_mini is active and
			# damage_to_take_from_activating_ability is > 10
			organism.damage_to_take_from_activating_ability = \
				max(10, organism.damage_to_take_from_activating_ability)
		return true
	return false

func A031_cleanup(player):
	for organism in game.curr_player.organisms:
		var message = organism.oname + " was cured of A031"
		game._root.create_notification(message, 10, organism.alignment)
		organism.damage_to_take_from_activating_ability = 0

func A032():
	game.next_player.change_HP(-15)
	var args = {'object': self, 'action': 'A032_mini',
				'num_times': 2, 'action_type': 'turn_start', 'cleanup': 'A032_cleanup'}
	game.register_repeated_action(args)

func A032_mini(player):
	if game.get_other_player(player) == game.curr_player:
		emit_signal("doing_mini_ability")
		for organism in game.curr_player.organisms:
			organism.damage_to_take_from_activating_ability = 15
		return true
	return false

func A032_cleanup(player):
	for organism in game.curr_player.organisms:
		var message = organism.oname + " was cured of A032"
		game._root.create_notification(message, 10, organism.alignment)
		organism.damage_to_take_from_activating_ability = 0

var A33or34 = []
func A033():
	game.next_player.change_HP(-15)
	var target_org = Utils.select_random_or_remaining(A33or34, game.next_player.organisms)
	if target_org == null:
		var message = "No targets were found for A033."
		game._root.create_notification(message, 10, alignment)
	
	target_org.change_extra_mana_to_activate(3)
	A33or34.append(target_org)
	var message = target_org.oname + " was afflicted with A033"
	game._root.create_notification(message, 10, target_org.alignment)
	
	var args = {'object': self, 'action': 'A033_mini',
				'num_times': 2, 'action_type': 'turn_start', 'cleanup': 'A033_cleanup'}
	game.register_repeated_action(args)

func A033_mini(player):
	if game.get_other_player(player) == game.curr_player:
		return true
	return false

func A033_cleanup(player):
	var target_org = A33or34.pop_front()
	target_org.change_extra_mana_to_activate(-3)
	var message = target_org.oname + " was cured of A033"
	game._root.create_notification(message, 10, target_org.alignment)

func A034():
	game.next_player.change_HP(-25)
	var target_org = Utils.select_random_or_remaining(A33or34, game.next_player.organisms)
	if target_org == null:
		var message = "No targets were found for A034."
		game._root.create_notification(message, 10, alignment)
	
	target_org.change_extra_mana_to_activate(3)
	A33or34.append(target_org)
	var message = target_org.oname + " was afflicted with A034"
	game._root.create_notification(message, 10, alignment)
	
	var args = {'object': self, 'action': 'A034_mini',
				'num_times': 3, 'action_type': 'turn_start', 'cleanup': 'A034_cleanup'}
	game.register_repeated_action(args)

func A034_mini(player):
	if game.get_other_player(player) == game.curr_player:
		return true
	return false

func A034_cleanup(player):
	var target_org = A33or34.pop_front()
	target_org.change_extra_mana_to_activate(-3)
	var message = target_org.oname + " was cured of A034"
	game._root.create_notification(message, 10, target_org.alignment)

func A035():
	game.next_player.change_HP(-10)
	var args = {'object': self, 'action': 'A035_mini',
				'num_times': 3, 'action_type': 'move_start'}
	game.register_repeated_action(args)

func A035_mini(player):
	if game.get_other_player(player) == game.curr_player:
		emit_signal("doing_mini_ability")
		Utils.select_random(game.get_other_player(player).organisms).change_mana(-1)
		return true
	return false

func A036():
	game.next_player.change_HP(-15)
	var args = {'object': self, 'action': 'A036_mini',
				'num_times': 3, 'action_type': 'move_start'}
	game.register_repeated_action(args)

func A036_mini(player):
	if game.get_other_player(player) == game.curr_player:
		emit_signal("doing_mini_ability")
		Utils.select_random(game.get_other_player(player).organisms).change_mana(-2)
		return true
	return false

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
