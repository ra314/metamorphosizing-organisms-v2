extends Node2D

# [num rows, num cols]
const grid_size = [5,7]

# 2d array containing tiles
var grid = []

onready var np = $Numpy
var Tile = load("res://Scenes/Levels/Level Components/Tile.tscn")
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	initialize_grid()
	remove_matched_tiles_and_fill_grid(find_matches_in_grid(), true)

# Create all tiles and randomly pick textures
func initialize_grid():
	for y in range(grid_size[0]):
		var row = []
		for x in range(grid_size[1]):
			row.append(Tile.instance().init(y, x, rng.randi(), self))
			add_child(row[-1])
		grid.append(row)

# Returns a 2d array where tiles that aren't part of a match are 0.
# Tiles that are part of a match retain their number.
func find_matches_in_grid():
	var matches = np.zeros(grid_size)
	for y in range(grid_size[0]):
		for x in range(grid_size[1]):
			var curr_tile = grid[y][x].value
			# Check for matches above the curr tile
			if y - 2 >= 0:
				if grid[y - 1][x].value == curr_tile and grid[y - 2][x].value == curr_tile:
					matches[y][x] = curr_tile
					matches[y - 1][x] = curr_tile
					matches[y - 2][x] = curr_tile

			# Check for matches to the left of the curr tile
			if x - 2 >= 0:
				if grid[y][x - 1].value == curr_tile and grid[y][x - 2].value == curr_tile:
					matches[y][x] = curr_tile
					matches[y][x - 1] = curr_tile
					matches[y][x - 2] = curr_tile
	
	return matches

# True if coordinates are inside the grid, false otherwise
func inside_grid(y,x):
	return (x>=0) and (y>=0) and (x<grid_size[1]) and (y<grid_size[0])

# Performs flood fill from the provided coordinates.
# Fills like a flood for every tile that is the same tile type as the tile type at the provided coordinates.
# 123
# 122
# 451
# For example if flood fill was performed at the center of the image above, the
# returned value is 3. Since 3 2's are connected by adjacency.
func flood_fill(y, x, matrix):
	var curr_tile = matrix[y][x]
	var queue = [[y,x]]
	var match_size = 1
	var processed_tiles = [str(y) + "," + str(x)]
	
	while queue != []:
		var curr = queue.pop_back()
		y = curr[0]
		x = curr[1]
		for delta in [[-1,0],[1,0],[0,-1],[0,1]]:
			var dy = delta[0]
			var dx = delta[1]
			if inside_grid(y+dy, x+dx):
				if matrix[y+dy][x+dx] == curr_tile:
					var str_dxdy = str(y+dy) + "," + str(x+dx)
					if not (str_dxdy in processed_tiles):
						match_size += 1
						queue.append([y+dy, x+dx])
						processed_tiles.append(str_dxdy)
	
	return match_size

# Returns true if there is a continuous region of matches tiles bigger than 3
func check_for_extra_move(matches):
	for y in range(grid_size[0]):
		for x in range(grid_size[1]):
			if matches[y][x] != 0:
				if flood_fill(y, x, matches) > 3:
					return true
	return false

func remove_matched_tiles_and_fill_grid(matches, animate=true):
	matches = matches.duplicate()
	
	# Remove the tiles that are part of a match
	for y in range(grid_size[0]):
		for x in range(grid_size[1]):
			if matches[y][x] != 0:
				# Tile will have a disappear animation but the place it occupied will be null
				remove_tile(grid[y][x])
				grid[y][x] = null
	
	# We want to iterate from the bottom row up
	var ys = range(grid_size[0])
	ys.invert()
	
	# Moves from column to column then row by row, starting from the bottom row
	# [0, 7] -> [0, 6] -> etc...
	# [1, 7] -> [1, 6] -> etc...
	for x in range(grid_size[1]):
		var num_new_tiles_in_columns = 0
		for y in ys:
			# Check if the tile is in |matches|
			if matches[y][x] != 0:
				# Returns the first tile upward of the current tile that isn't in |matches|
				# This "unmatched_tile" will take the place of the current tile
				var unmatched_tile_coordinate = find_unmatched_tile(y, x, matches)
				
				# Create a new tile
				if unmatched_tile_coordinate == null:
					num_new_tiles_in_columns += 1
					grid[y][x] = Tile.instance().init(-num_new_tiles_in_columns, x, rng.randi(), self)
					add_child(grid[y][x])
				# Shift down existing tile
				else:
					var new_y = unmatched_tile_coordinate[0]
					var new_x = unmatched_tile_coordinate[1]
					grid[y][x] = grid[new_y][new_x]
					# Mark the "unmatched_tile" as matched since it is being 
					# used now for the current tile.
					matches[new_y][new_x] = 10
				animation_durations.append(grid[y][x].move_tile(y, x, animate))
	yield(animate(), "completed")

func force_grid_match(height, width, num_shapes):
	# Replace -1s with height and width of grid
	if height == -1:
		height = grid_size[0]
	if width == -1:
		width = grid_size[1]
	
	var matches = np.zeros(grid_size)
	for i in range(num_shapes):
		# Pick a random tile and check that the shape is inside the grid
		var coords
		while true:
			coords = generate_random_coordinates()
			if shape_in_grid(height, width, coords):
				break
		
		# Checking that where the shape is placed does not interefe with already matched tiles
		for y in range(coords[0], coords[0] + height):
			for x in range(coords[1], coords[1] + width):
				if matches[y][x] != 0:
					continue
		
		# Mark the tiles within the shape as matched
		for y in range(coords[0], coords[0] + height):
			for x in range(coords[1], coords[1] + width):
				matches[y][x] = grid[y][x].value
	
	emit_signal("collect_mana", get_matches_array(matches))
	yield(remove_matched_tiles_and_fill_grid(matches, true), "completed")
	while np.sum2d(find_matches_in_grid()):
		var matches_in_grid = find_matches_in_grid()
		emit_signal("collect_mana", get_matches_array(matches_in_grid))
		if check_for_extra_move(matches_in_grid):
			emit_signal("extra_move")
		yield(remove_matched_tiles_and_fill_grid(matches_in_grid, true), "completed")

func generate_random_coordinates():
		var y = rng.randi() % grid_size[0]
		var x = rng.randi() % grid_size[1]
		return [y, x]

# Given a shape and coordinates will tell you if the shape is in the grid
func shape_in_grid(height, width, coords):
	# Start from the given seed and extend by the height and width of the shape
	# Check if these parts of the shape are also within the grid
	var y = coords[0]
	var x = coords[1]
	return y + height <= grid_size[0] and x + width <= grid_size[1]

# Look upwards in the grid until you find an unmatched tile
func find_unmatched_tile(y, x, matches):
	var new_y = y
	while new_y > 0:
		new_y -= 1
		if matches[new_y][x] != 0:
			continue
		else:
			return [new_y, x]
	return null

# Prints any grid along with its name
func print_grid(name, grid):
	print("Start of " + name + " Grid")
	for y in range(grid_size[0]):
		var row = ""
		for x in range(grid_size[1]):
			row += str(grid[y][x].value) + " "
		print(row)
	print("End of " + name + " Grid")
	print("")

var selected_tile = null
var in_middle_of_swap = false
func select_tile(tile):
	if not in_middle_of_swap:
		# Select new tile if no tile is currently selected
		if selected_tile == null:
			selected_tile = tile
		# Swap if the prev selected tile and curr selected tile are adjacent
		elif tile.can_swap(selected_tile):
			swap(tile, selected_tile)
			selected_tile = null
		# Deselection if you click the same tile twice
		elif selected_tile == tile:
			selected_tile = null
		# Select a different tile if the tile you just clicked was too far 
		# from the tile you previously clicked
		else:
			selected_tile = tile

# Stores the durations of all of the tile animations
var animation_durations = [0]
# Start tile animations, and wait until all of them are done
# This is done by waiting the duration of the longest tile animation
func animate():
	$Tween.start()
	yield(get_tree().create_timer(animation_durations.max()), "timeout")
	animation_durations = [0]

func move_tile(object, destination, duration, curr_position, delay):
	$Tween.interpolate_property(object, "rect_position", curr_position, destination, duration, Tween.TRANS_BOUNCE, Tween.EASE_OUT, delay)

const tile_disappear_speed = 1
func remove_tile(object):
	$Tween.interpolate_property(object, "rect_scale", object.rect_scale, Vector2(0, 0), tile_disappear_speed, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, tile_disappear_speed, "delete_tile", object)
	$Tween.start()

func delete_tile(tile):
	tile.queue_free()	

# Returns an array where each index contains the number of tiles matches of that type
# Eg: [0,0,3,0,0,0,0] = 3 water tiles
func get_matches_array(matches):
	var matches_array = np.zeros([7])
	for row in matches:
		for elem in row:
			matches_array[elem] += 1
	return matches_array

signal swap_start
signal swap_end
signal collect_mana
signal extra_move
func swap(tile1, tile2):
	emit_signal("swap_start")
	in_middle_of_swap = true
	
	var y1 = tile1.location[0]
	var x1 = tile1.location[1]
	var y2 = tile2.location[0]
	var x2 = tile2.location[1]
	
	grid[y2][x2] = tile1
	grid[y1][x1] = tile2
	
	animation_durations.append(tile1.move_tile(y2, x2, true, false))
	animation_durations.append(tile2.move_tile(y1, x1, true, false))
	yield(animate(), "completed")
	while np.sum2d(find_matches_in_grid()):
		var matches_in_grid = find_matches_in_grid()
		emit_signal("collect_mana", get_matches_array(matches_in_grid))
		if check_for_extra_move(matches_in_grid):
			emit_signal("extra_move")
		yield(remove_matched_tiles_and_fill_grid(matches_in_grid, true), "completed")
	
	in_middle_of_swap = false
	emit_signal("swap_end")

func convert_tiles(tile_type, num_tiles):
	for i in range(num_tiles):
		# Pick a random tile and check that the type is different to the desired type
		while true:
			var coords = generate_random_coordinates()
			var y = coords[0]
			var x = coords[1]
			if grid[y][x].value != ManaTex.enum(tile_type):
				remove_tile(grid[y][x])
				grid[y][x] = Tile.instance().init(y, x, ManaTex.enum(tile_type), self)
				add_child(grid[y][x])
				break
