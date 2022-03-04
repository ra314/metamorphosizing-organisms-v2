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
	print_grid("grid", grid)
	remove_matched_tiles_and_fill_grid(find_matches_in_grid(), true)

# Create all tiles and randomly pick textures
func initialize_grid():
	for y in range(grid_size[0]):
		var row = []
		for x in range(grid_size[1]):
			row.append(Tile.instance().init(y, x, rng.randi(), $Tween, self))
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
	
	while queue:
		var curr = queue.pop_back()
		y = curr[0]
		x = curr[1]
		for delta in [[-1,0],[1,0],[0,-1],[0,1]]:
			var dy = delta[0]
			var dx = delta[1]
			if inside_grid(y+dy, x+dx):
				if matrix[y+dy][x+dx] == curr_tile:
					match_size += 1
					queue.append([y+dy, x+dx])
	
	return match_size

# Returns true if there is a continuous region of matches tiles bigger than 3
func check_for_extra_move():
	var matches = find_matches_in_grid()
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
				grid[y][x].visible = false
				grid[y][x].queue_free()
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
					grid[y][x] = Tile.instance().init(-num_new_tiles_in_columns, x, rng.randi(), $Tween, self)
					add_child(grid[y][x])
				# Shift down existing tile
				else:
					var new_y = unmatched_tile_coordinate[0]
					var new_x = unmatched_tile_coordinate[1]
					grid[y][x] = grid[new_y][new_x]
					# Mark the "unmatched_tile" as matched since it is being 
					# used now for the current tile.
					matches[new_y][new_x] = 10
				grid[y][x].move_tile(y, x, animate)
	$Tween.start()

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
func select_tile(tile):
	print("trying to swap")
	if selected_tile == null:
		selected_tile = tile
	elif tile.can_swap(selected_tile):
		print('can swap')
		swap(tile, selected_tile)
		selected_tile = null
	elif selected_tile == tile:
		selected_tile = null

func swap(tile1, tile2):
	var y1 = tile1.location[0]
	var x1 = tile1.location[1]
	var y2 = tile2.location[0]
	var x2 = tile2.location[1]
	grid[y2][x2] = tile1.location
	grid[y1][x1] = tile2.location
	tile1.move_tile(y2, x2, true)
	tile2.move_tile(y1, x1, true)
	$Tween.start()
