extends Node

var rng = RandomNumberGenerator.new()

func select_random(array):
	return array[index_random(array)]

func index_random(array):
	return rng.randi() % len(array)

func select_random_and_remove(array):
	var index = index_random(array)
	var selection = array[index]
	array.remove(index)
	return selection
