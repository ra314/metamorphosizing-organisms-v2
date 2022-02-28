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
	print(find_matches_in_grid())

var rng = RandomNumberGenerator.new()

func generate_tile_index():
	return rng.randi() % len(texture_arr)

# Add empty sprites to grid_tex and creates 0's for grid_matrix
func create_empty_grid():
	for y in range(grid_size[0]):
		var row = []
		for x in range(grid_size[1]):
			var sprite = Sprite.new()
			sprite.centered = false
			sprite.scale *= tile_scale_factor
			sprite.position = Vector2(x, y)*sprite_size*tile_scale_factor
			add_child(sprite)
			row.append(sprite)
		grid_tex.append(row)
	grid_matrix = np.zeros(grid_size)

# Randomly pick textures
func initialize_grid():
	for y in range(grid_size[0]):
		for x in range(grid_size[1]):
			grid_matrix[y][x] = generate_tile_index()
			grid_tex[y][x].texture = texture_arr[grid_matrix[y][x]]

# Returns a 2d array with 1's where there are tiles that form a match
func find_matches_in_grid():
	var matches = np.zeros(grid_size)
	for y in range(grid_size[0]):
		for x in range(grid_size[1]):
			var curr_tile = grid_matrix[y][x]
			# Check for matches above the curr tile
			if y - 2 >= 0:
				if grid_matrix[y - 1][x] == curr_tile and grid_matrix[y - 2][x] == curr_tile:
					matches[y][x] = 1
					matches[y - 1][x] = 1
					matches[y - 2][x] = 1

			# Check for matches to the left of the curr tile
			if x - 2 >= 0:
				if grid_matrix[y][x - 1] == curr_tile and grid_matrix[y][x - 2] == curr_tile:
					matches[y][x] = 1
					matches[y][x - 1] = 1
					matches[y][x - 2] = 1
	
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
func flood_fill(y, x):
	var curr_tile = grid_matrix[y][x]
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
				if grid_matrix[y+dy][x+dx] == curr_tile:
					match_size += 1
					queue.append([y+dy, x+dx])
	
	return match_size
