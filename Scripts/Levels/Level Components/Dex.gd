extends Node

var data

# Called when the node enters the scene tree for the first time.
func init():
	data = File.new()
	data.open("res://data.save", File.READ)
	data = JSON.parse(data.get_as_text()).result
