extends TextureButton

const tile_scale_factor = 0.25
const sprite_size = 512

const textures_dict = {
	"null": null,
	"fire": preload("res://Assets/UI/Tiles/Tile_Fire.png"),
	"water": preload("res://Assets/UI/Tiles/Tile_Water.png"),
	"electric": preload("res://Assets/UI/Tiles/Tile_Electric.png"),
	"grass": preload("res://Assets/UI/Tiles/Tile_Grass.png"),
	"psychic": preload("res://Assets/UI/Tiles/Tile_Psychic.png"),
	"berry": preload("res://Assets/UI/Tiles/Tile_Berry.png")}
var texture_arr = textures_dict.values()

# The index of the texture
var value

# The tween node of the Grid that is composed of tiles
var tween

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func change_tile_texture(tex_num):
	texture_normal = texture_arr[tex_num]

func randomize_tile_tex(rand_num):
	value = (rand_num % (len(texture_arr)-1))+1
	change_tile_texture(value)

func init(y, x, rand_num, _tween):
	rect_scale *= tile_scale_factor
	rect_position = get_tile_position(y, x)
	tween = _tween
	randomize_tile_tex(rand_num)
	return self

func vec_sum(array):
	return array[0] + array[1]

# This is the speed of the movement of the tile
# Eg: 2 -> 2 seconds to move from [3,4] to [2,4]
const seconds_per_tile = 1
# If animate is false, the movement is instant with no tween used.
func move_tile(y, x, animate):
	var destination = Vector2(x, y) * sprite_size * tile_scale_factor
	if animate:
		var duration = vec_sum((rect_position - destination).abs()) / (sprite_size*tile_scale_factor) * seconds_per_tile
		tween.interpolate_property(self, "rect_position", rect_position, destination, duration, tween.TRANS_BOUNCE, tween.EASE_OUT)
	else:
		rect_position = destination

# Takes in grid position, returns pixel position
func get_tile_position(y, x):
	return Vector2(x, y) * sprite_size * tile_scale_factor
