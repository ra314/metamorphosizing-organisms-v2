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

