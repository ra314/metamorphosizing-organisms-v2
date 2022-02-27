extends Node2D

const grid_size = Vector2(7, 5)
const tile_scale_factor = 0.25
const sprite_size = 512

# 2d array containing sprites
var grid = []
const textures_dict = {
	"fire": preload("res://Assets/UI/Tiles/Tile_Fire.png"),
	"water": preload("res://Assets/UI/Tiles/Tile_Water.png"),
	"electric": preload("res://Assets/UI/Tiles/Tile_Electric.png"),
	"grass": preload("res://Assets/UI/Tiles/Tile_Grass.png"),
	"psychic": preload("res://Assets/UI/Tiles/Tile_Psychic.png"),
	"berry": preload("res://Assets/UI/Tiles/Tile_Berry.png")}
var texture_arr = textures_dict.values()

func _ready():
	# Initializing var grid with sprites
	for y in range(grid_size.y):
		var row = []
		for x in range(grid_size.x):
			var sprite = Sprite.new()
			sprite.centered = false
			sprite.scale *= tile_scale_factor
			sprite.texture = texture_arr[generate_tile_index()]
			sprite.position = Vector2(x, y)*sprite_size*tile_scale_factor
			print(str(x) + "/" + str(y))
			print(sprite.position)
			add_child(sprite)
			row.append(sprite)
		grid.append(row)
	
#	rng.randomize()
#	initialize_grid()
	grid[0][0].texture = textures_dict["water"]

var rng = RandomNumberGenerator.new()

func generate_tile_index():
	return rng.randi() % len(texture_arr)

func initialize_grid():
	for y in range(grid_size[1]):
		for x in range(grid_size[0]):
			grid[y][x].texture = textures_dict["fire"]
			print(grid[y][x].texture)
