extends Node

var grid = [[]]
var width
var height
var max_num_columns
var curr_row = 0
var curr_col = 0
var offset = Vector2()

func _ready():
	pass # Replace with function body.

func init(_width, _height, _max_num_columns, _offset):
	width = _width
	height = _height
	max_num_columns = _max_num_columns
	offset = _offset

func add_object(object):
	object.position = Vector2(width*curr_col, height*curr_row) + offset
	
	grid[-1].append(object)
	curr_col += 1
	
	if curr_col == max_num_columns:
		grid.append([])
		curr_col = 0
		curr_row += 1
