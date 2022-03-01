extends Node2D

# [num rows, num cols]
const grid_size = [5,7]
const tile_scale_factor = 0.25
const sprite_size = 512

# 2d array containing sprites
var grid_tex = []
# 2d array containing numbers that refer to each element
var grid_matrix = []

const textures_dict = {
	"null": null,
	"fire": preload("res://Assets/UI/Tiles/Tile_Fire.png"),
	"water": preload("res://Assets/UI/Tiles/Tile_Water.png"),
	"electric": preload("res://Assets/UI/Tiles/Tile_Electric.png"),
	"grass": preload("res://Assets/UI/Tiles/Tile_Grass.png"),
	"psychic": preload("res://Assets/UI/Tiles/Tile_Psychic.png"),
	"berry": preload("res://Assets/UI/Tiles/Tile_Berry.png")}
var texture_arr = textures_dict.values()

onready var np = $Numpy

func _ready():
	rng.randomize()
	create_empty_grid()
	initialize_grid()
	# print(find_matches_in_grid())
	# Adjusted for readability
	var matches = [[0, 0, 0, 0, 0, 0, 0],
				   [0, 0, 6, 6, 6, 0, 0], 
				   [0, 0, 0, 0, 0, 0, 0], 
				   [0, 0, 0, 0, 0, 0, 0], 
				   [0, 0, 0, 0, 0, 0, 0]]
	remove_matched_tiles_and_fill_grid(matches)

var rng = RandomNumberGenerator.new()

func generate_tile_index():
	return (rng.randi() % (len(texture_arr)-1))+1

# Add empty sprites to grid_tex and creates 0's for grid_matrix
func create_empty_grid():
	for y in range(grid_size[0]):
		var row = []
		for x in range(grid_size[1]):
			row.append(create_new_tile(y, x))
		grid_tex.append(row)
	grid_matrix = np.zeros(grid_size)

func create_new_tile(y, x):
	var sprite = Sprite.new()
	sprite.centered = false
	sprite.scale *= tile_scale_factor
	sprite.position = get_tile_position(y, x)
	add_child(sprite)
	return sprite

# Takes in grid position, returns pixel position
func get_tile_position(y, x):
	return Vector2(x, y) * sprite_size * tile_scale_factor

# Randomly pick textures
func initialize_grid():
	for y in range(grid_size[0]):
		for x in range(grid_size[1]):
			grid_matrix[y][x] = generate_tile_index()
			grid_tex[y][x].texture = texture_arr[grid_matrix[y][x]]

# Returns a 2d array where tiles that aren't part of a match are 0.
# Tiles that are part of a match retain their number.
func find_matches_in_grid():
	var matches = np.zeros(grid_size)
	for y in range(grid_size[0]):
		for x in range(grid_size[1]):
			var curr_tile = grid_matrix[y][x]
			# Check for matches above the curr tile
			if y - 2 >= 0:
				if grid_matrix[y - 1][x] == curr_tile and grid_matrix[y - 2][x] == curr_tile:
					matches[y][x] = curr_tile
					matches[y - 1][x] = curr_tile
					matches[y - 2][x] = curr_tile

			# Check for matches to the left of the curr tile
			if x - 2 >= 0:
				if grid_matrix[y][x - 1] == curr_tile and grid_matrix[y][x - 2] == curr_tile:
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

func remove_matched_tiles_and_fill_grid(matches):
	matches = matches.duplicate()
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
				# Delete the matched tile
				grid_tex[y][x].visible = false
				# grid_tex[y][x].queue_free()
				# grid_tex[y][x] = null
				
				# Returns the first tile that isn't in |matches|
				var unmatched_tile_coordinate = find_unmatched_tile(y, x, matches)
				
				# Create a new tile
				if unmatched_tile_coordinate == null:
					grid_matrix[y][x] = generate_tile_index()
					grid_tex[y][x].visible = true
					grid_tex[y][x] = create_new_tile(-num_new_tiles_in_columns, x)
					grid_tex[y][x].texture = texture_arr[grid_matrix[y][x]]
					grid_tex[y][x].position = Vector2(x, y - 1) * sprite_size * tile_scale_factor
					move_tile(y, x, grid_tex[y][x])
					num_new_tiles_in_columns += 1
				# Shift down existing tile
				else:
					var new_y = unmatched_tile_coordinate[0]
					var new_x = unmatched_tile_coordinate[1]
					grid_tex[y][x] = grid_tex[new_y][new_x]
					grid_matrix[y][x] = grid_matrix[new_y][new_x]
				
				if y > 0:
					# Just marking the tile above the current tile as empty
					matches[y-1][x] = 10
				move_tile(y, x, grid_tex[y][x])
	$Tween.start()
	print_grid("Matrix", grid_matrix)

func vec_sum(array):
	return array[0] + array[1]

# This is the speed of the movement of the tile
# Eg: 2 -> 2 seconds to move from [3,4] to [2,4]
const seconds_per_tile = 1
func move_tile(y, x, tile):
	var destination = Vector2(x, y) * sprite_size * tile_scale_factor
	var duration = vec_sum((tile.position - destination).abs()) / (sprite_size*tile_scale_factor) * seconds_per_tile
	$Tween.interpolate_property(tile, "position", tile.position, destination, duration, Tween.TRANS_BOUNCE, Tween.EASE_OUT)

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
	for y in range(len(grid)):
		print(grid[y])
	print("End of " + name + " Grid")
	print("")
