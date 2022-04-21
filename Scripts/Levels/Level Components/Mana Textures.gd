extends Node

const dict = {
	"null": null,
	"fire": preload("res://Assets/UI/Tiles/Tile_Fire.png"),
	"water": preload("res://Assets/UI/Tiles/Tile_Water.png"),
	"electric": preload("res://Assets/UI/Tiles/Tile_Electric.png"),
	"grass": preload("res://Assets/UI/Tiles/Tile_Grass.png"),
	"psychic": preload("res://Assets/UI/Tiles/Tile_Psychic.png"),
	"berry": preload("res://Assets/UI/Tiles/Tile_Berry.png")}

# Used in the color for the Mana Bars
# Will use for other assets too

const colors = {
	"null": null,
	"fire": Color.red,
	"water": Color.cyan,
	"electric": Color.yellow,
	"grass": Color.green,
	"psychic": Color.purple,}

var values = dict.values()
var keys = dict.keys()

# Returns the index of the provided mana_type
func enum(mana_type):
	return keys.find(mana_type)
	
func enum_value(mana_index):
	return keys[mana_index]
