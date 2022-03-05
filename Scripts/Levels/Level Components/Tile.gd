extends TextureButton

const tile_scale_factor = 0.25
const sprite_size = 512

# The index of the texture
var value
# The grid coordinate of the tile
var location

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func change_tile_texture(tex_num):
	value = tex_num
	texture_normal = ManaTex.values[tex_num]

func randomize_tile_tex(rand_num):
	value = (rand_num % (len(ManaTex.values)-1))+1
	change_tile_texture(value)

# The value of rand_num will be the tile texture we'll force if force_type is true
func init(y, x, rand_num, _grid, force_type = false):
	rect_scale *= tile_scale_factor
	rect_position = get_tile_position(y, x)
	location = Vector2(y, x)
	connect("button_down", _grid, "select_tile", [self])
	connect("move_tile", _grid, "move_tile")
	if force_type:
		change_tile_texture(rand_num)
	else:
		randomize_tile_tex(rand_num)
	return self

func can_swap(other_tile):
	return vec_sum((location-other_tile.location).abs()) == 1

func vec_sum(array):
	return array[0] + array[1]

# The formula for calculating the amount of time it takes a tile to fall is...
# base_seconds_per_tile + distance * seconds_per_tile * seconds_per_tile_scale
# 1 + distance * 0.25 * 0.25 or 1 + distance / 16

# The miniumum amount of time the falling animation can take
const base_seconds_per_tile = 0.5
# This is the speed of the movement of the tile
# Eg: 2 -> 2 seconds to move from [3,4] to [2,4]
const seconds_per_tile = 0.25
# How much more the seconds_per_tile can deviate from the base value
# 
# Eg: If a tile that falls 1 tile down takes 1 second to fall
# With a scale of 0.5, A tile that falls 1 tile down will take 0.5 seconds instead
const seconds_per_tile_scale = 0.25
# The delay before the tiles move to their current location
# allows the disappearing animation to be more visible
const tile_move_delay = 0.75

signal move_tile
func move_tile(y, x, animate, falling = true):
	location = Vector2(y, x)
	var destination = Vector2(x, y) * sprite_size * tile_scale_factor
	var duration
	
	var delay
	if falling:
		delay = tile_move_delay
	else:
		delay = 0
		
	if animate:
		duration = base_seconds_per_tile + vec_sum((rect_position - destination).abs()) / (sprite_size*tile_scale_factor) * seconds_per_tile * seconds_per_tile_scale
		emit_signal("move_tile", self, destination, duration, rect_position, delay)
	else:
		duration = 0
		rect_position = destination
	return duration + delay

# Takes in grid position, returns pixel position
func get_tile_position(y, x):
	return Vector2(x, y) * sprite_size * tile_scale_factor
