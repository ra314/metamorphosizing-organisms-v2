extends TextureButton

const tile_scale_factor = 0.25
const sprite_size = 512



# The index of the texture
var value
# The tween node of the Grid that is composed of tiles
var tween
# The grid coordinate of the tile
var location

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func change_tile_texture(tex_num):
	texture_normal = ManaTex.arr[tex_num]

func randomize_tile_tex(rand_num):
	value = (rand_num % (len(ManaTex.arr)-1))+1
	change_tile_texture(value)

func init(y, x, rand_num, _tween, _grid):
	rect_scale *= tile_scale_factor
	rect_position = get_tile_position(y, x)
	location = Vector2(y, x)
	tween = _tween
	connect("button_down", _grid, "select_tile", [self])
	randomize_tile_tex(rand_num)
	return self

func can_swap(other_tile):
	return vec_sum((location-other_tile.location).abs()) == 1

func vec_sum(array):
	return array[0] + array[1]

# This is the speed of the movement of the tile
# Eg: 2 -> 2 seconds to move from [3,4] to [2,4]
const seconds_per_tile = 1
# If animate is false, the movement is instant with no tween used.
func move_tile(y, x, animate):
	location = Vector2(y, x)
	var destination = Vector2(x, y) * sprite_size * tile_scale_factor
	if animate:
		var duration = vec_sum((rect_position - destination).abs()) / (sprite_size*tile_scale_factor) * seconds_per_tile
		tween.interpolate_property(self, "rect_position", rect_position, destination, duration, tween.TRANS_BOUNCE, tween.EASE_OUT)
	else:
		rect_position = destination

# Takes in grid position, returns pixel position
func get_tile_position(y, x):
	return Vector2(x, y) * sprite_size * tile_scale_factor
