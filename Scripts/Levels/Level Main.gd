extends Node2D

onready var _root: Main = get_tree().get_root().get_node("Main")

var game_over = false

var curr_player : Player
var next_player : Player
const num_players = 2
var players = []
func change_to_next_player():
	var temp_player = curr_player
	curr_player = next_player
	next_player = temp_player

var game_started = false
var world_str = ""
var world_details = ""
var grid = null

var curr_moves = 2
var max_moves = 2
const absolute_max_moves = 3
var earned_extra_move = false

var curr_time = 0
const time_per_move = 30

func create_mons_and_players():
	for i in range(len(_root.players_for_level_main)):
		var info = _root.players_for_level_main[i]
		var mon1_name = info[0]
		var mon2_name = info[1]
		var player_index = i
		
		var player = get_node("Players/Player" + str(player_index+1))
		player.get_node("Organism1").create_base_mon(mon1_name)
		player.get_node("Organism2").create_base_mon(mon2_name)
		player.init("P"+str(player_index+1))
		_root.players_for_level_main[player_index] = player

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create the player and organism objects and store them
	create_mons_and_players()
	players = _root.players_for_level_main
	grid = $Grid
	grid.online_game = _root.online_game
	
	# Flip the sprites of the organisms in Player 2's control
	for organism in players[1].organisms:
		organism.flip_sprite()
	
	# Setting the current and next players
	curr_player = players[0]
	next_player = players[1]
	
	# Give the second player 90 HP as opposed to the default of 80HP.
	next_player.curr_HP = 90
	next_player.update_ui()
	next_player.flip_ui()
	
	# Giving the organisms and players a reference to the game
	for player in players:
		for organism in player.organisms:
			organism.game = self
		player.game = self
	
	# Creating notifications for evolution, boosting and triggering of abilities
	for player in players:
		for organism in player.organisms:
			organism.alignment = Label.ALIGN_LEFT if player.pname == "P1" else Label.ALIGN_RIGHT
	for player in players:
		for organism in player.organisms:
			organism.connect("evolving_start", _root, "create_notification",
				[organism.oname + " is evolving.", 3, organism.alignment])
			organism.connect("boost", _root, "create_notification",
				[organism.oname + " is boosting.", 3, organism.alignment])
			# Theres a reason this one signal needs create_organism_ability_notification
			# Connections are set at initialization, so when an organism evoles
			# and it's ability description changes, this isn't reflected in the notification
			organism.connect("doing_ability", self, "create_organism_ability_notification",
				[organism, 10])
			organism.connect("doing_mini_ability", self, "create_organism_mini_ability_notification",
				[organism, 10])
	
	# Triggering turn end stuff for evolution and boosting
	for player in players:
		for organism in player.organisms:
			organism.connect("evolving_start", self, "before_process")
			organism.connect("evolving_end", self, "after_process")
		player.connect("boost_start", self, "before_process")
		player.connect("boost_end", self, "after_process")
	
	# Popup of information when clicking on organisms
	for player in players:
		for organism in player.organisms:
			organism.connect("long_press", _root, "popup_organism")
	
	# Setting up custom stages
	world_str = _root.world_str
	world_details = _root.world_details
	if world_str == "Forest Valley":
		for player in players:
			player.max_berries = 3
			player.update_ui()
	elif world_str == "Abandoned Town":
		for player in players:
			for organism in player.organisms:
				organism.connect("evolving_end", player, "change_HP", [10])
	elif world_str == "Tranquil Falls":
		connect("turn_starting", grid, "shuffle_tiles", [ManaTex.enum("water")])
	elif world_str == "Lava Caverns":
		grid.connect("collect_mana_from_grid", self, "lava_damage_player")
	
	grid.connect("swap_start", self, "before_process")
	grid.connect("swap_end", self, "after_process")
	grid.connect("shuffle_tiles_end", self, "after_process")
	grid.connect("shuffle_tiles_end", self, "update_curr_player_ui_and_show_berries")
	grid.connect("collect_mana_from_grid", self, "distribute_mana")
	grid.connect("extra_move", self, "add_extra_move")
	grid.ready()
	
	$CanvasLayer/Help.connect("button_down", _root, "open_popup", [world_str, world_details])
	$CanvasLayer/Clear.connect("button_down", _root, "clear_all_notifications")
	
	start_turn()

func update_curr_player_ui_and_show_berries():
	curr_player.update_ui(true)

func create_organism_ability_notification(organism, duration):
	_root.create_notification(organism.ability_description, duration, organism.alignment)

func create_organism_mini_ability_notification(organism, duration, alignment):
	var message = organism.oname + "'s " + organism.ability + " was triggered."
	_root.create_notification(message, duration, organism.alignment)

func lava_damage_player(mana_array):
	if mana_array[ManaTex.enum("fire")]:
		next_player.change_HP(-5)

func distribute_mana(mana_array):
	mana_array = mana_array.duplicate()
	var berries_to_give = mana_array[ManaTex.enum("berry")]
	mana_array[ManaTex.enum("berry")] -= curr_player.change_berries(berries_to_give)
	# Distribute mana equally if both organisms are the same type
	if curr_player.organisms[0].mana_type == curr_player.organisms[1].mana_type:
		var mana_enum = curr_player.organisms[0].mana_enum
		while mana_array[mana_enum] > 0 and not curr_player.is_full_of_mana():
			for organism in curr_player.organisms:
				if mana_array[mana_enum] > 0:
					mana_array[mana_enum] -= organism.change_mana(1)
	# Distribution of mana if organisms are of different types
	else:
		for organism in curr_player.organisms:
			var mana_to_give = mana_array[organism.mana_enum]
			mana_array[organism.mana_enum] -= organism.change_mana(mana_to_give)

signal turn_starting
func start_turn():
	curr_moves = 2
	max_moves = 2
	restart_timer()
	update_move_icons()
	update_turn_icons()
	curr_player.update_ui(true)
	emit_signal("turn_starting")

# extra_move_tiles: The tiles that were matched to produce the extra move
func add_extra_move(extra_move_tiles):
	if max_moves == absolute_max_moves:
		return
	
	curr_moves += 1
	max_moves += 1
	update_move_icons()
	
	if extra_move_tiles:
		yield(show_extra_move_text(extra_move_tiles), "completed")

func show_extra_move_text(extra_move_tiles):
	var extra_move_text = get_node("Match_Control/Extra_Move")
	# Get all the tiles that were part of the extra move and flash them
	for tile in extra_move_tiles:
		tile.flash()
	extra_move_text.rect_global_position = grid.get_central_location(extra_move_tiles)
	
	# Makes the text fade in for 2 seconds then fade out for 1 second
	$Tween.interpolate_property(extra_move_text, "modulate", Color.transparent, Color.white, 2, Tween.TRANS_BACK, Tween.EASE_OUT)
	$Tween.interpolate_property(extra_move_text, "modulate", Color.white, Color.transparent, 1, Tween.TRANS_BACK, Tween.EASE_OUT, 2)
	$Tween.start()
	
	# Waiting for 2 seconds so that the animation is clear
	yield(get_tree().create_timer(2), "timeout")
	
	return null

func remove_move():
	if curr_moves > 0:
		curr_moves -= 1
		update_move_icons()

# Called when the grid starts processing a move
func before_process():
	var timer = $Match_Control/Time_Control/Time_Text/Timer
	timer.stop()
	
	# Assuming that level main handles all the moves, player moves will update here
	remove_move()
	process_actions(actions['move_start'])

# Called when the grid is done processing a move
func after_process():
	yield(grid.cascading_grid_match_and_distribute(), "completed")
	process_actions(actions['move_end'])
	restart_timer()
	update_move_icons()
	
	for organism in curr_player.organisms:
		organism.do_ability()
		for player in players:
			if is_game_over(curr_player):
				end_game(curr_player)
				return
	
	# Changing turns
	if curr_moves == 0:
		process_actions(actions['turn_end'])
		curr_player.update_ui()
		
		if is_game_over(curr_player):
			end_game(curr_player)
			return
			
		change_to_next_player()
		start_turn()
		process_actions(actions['turn_start'])
		
		if is_game_over(curr_player):
			end_game(curr_player)
			return
		
		grid.selected_tile = null
		# Notify the current player
		if is_current_player():
			notify()
	else:
		curr_player.update_ui(true)
		
func is_game_over(loser : Player):
	return loser.curr_HP == 0

func end_game(loser : Player):
	grid.game_over = true
	_root.create_notification(loser.pname + " has lost.", 10)

func compare_actions(action1, action2):
	return action1['num_times'] > action2['num_times']

func process_actions(curr_actions):
	# Why sort the actions?
	# Consider the ability that prevent an organism from absorbing mana
	# It could be on that in the list of actions there's 2 instances of this ability
	# We don't want the blocking mana to be set to true in the cleanup
	# if there's still another blocking mana ability with a longer duration that can set it to false
	# We sort to get around this
	curr_actions.sort_custom(self, "compare_actions")
	for a in curr_actions:
		if a['num_times'] > 0:
			# Check if the action can be executed and execute it
			if a['object'].call(a['action'], a['caster']):
				a['num_times'] -= 1
				
		if a['num_times'] == 0 and ('cleanup' in a):
			# Call cleanup at end of turn
			if a['action_type'] == 'turn_end':
				a['object'].call(a['cleanup'], a['caster'])
			else:
				var args = {'num_times': 1, 'action': a['cleanup'], 
							'caster': a['caster'], 'object': a['object'],
							'action_type': 'move_end'}
				actions['move_end'].append(args)
			a['num_times'] -= 1

const actions = {'turn_end': [], 'turn_start': [], 'move_start': [], 'move_end': []}
const register_repeated_action_args = {'num_times': 0, 'action': 0, 'caster': 0, 
	'object': 0, 'action_type': 0, 'cleanup': 0, 'cleanup_type': 0}
func register_repeated_action(args: Dictionary):
	args['caster'] = curr_player
	actions[args['action_type']].append(args)

var move_icon_active = load("res://Assets/UI/Player/Game_Player_Moves_Icon_Active.png")
var move_icon_used = load("res://Assets/UI/Player/Game_Player_Moves_Icon_Used.png")
onready var move_icons = $Match_Control/Moves_Control/Moves_Container
func update_move_icons():
	# Hide all move icons first
	for move_icon in move_icons.get_children():
		move_icon.visible = false
		
	# Set a tile visible based on how many max moves I have
	for i in range(max_moves):
		move_icons.get_children()[i].visible = true
	
	# Set all the icons' textures to used move texture
	for move_icon in move_icons.get_children():
		move_icon.texture = move_icon_used
		
	# Set a icon's texture to active_move for every move I currently have
	for i in range(curr_moves):
		move_icons.get_children()[i].texture = move_icon_active

func update_turn_icons():
	var dark = Color(0.5, 0.5, 0.5, 1)
	var light = Color(1, 1, 1, 1)
	
	# If the current player is Player #1, darken the Player 2 Icon
	if curr_player == players[0]:
		$Player2_Turn.modulate = dark
		$Player1_Turn.modulate = light
	else:
		$Player1_Turn.modulate = dark
		$Player2_Turn.modulate = light

# Restart the move timer
func restart_timer():
	curr_time = time_per_move
	$Match_Control/Time_Control/Time_Text.text = str(curr_time)
	
	var timer = $Match_Control/Time_Control/Time_Text/Timer
	
	timer.start()
	timer.connect("timeout", self, "on_timer_timeout") 

# The timer waits every second but don't update the text. We do it here.
func on_timer_timeout():
	curr_time -= 1
	$Match_Control/Time_Control/Time_Text.text = str(curr_time)

func is_current_player():
	if not _root.online_game:
		return true
	return players[_root.player_index] == curr_player
	
# Given a player object, return the other player object (This is a 2 person game)
func get_other_player(input_player):
  var local_players = players.duplicate()
  local_players.remove(local_players.find(input_player))
  return local_players[0]

func notify():
	$Notification.play()
