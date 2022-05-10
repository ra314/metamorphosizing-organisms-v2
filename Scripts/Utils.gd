extends Node

var rng = RandomNumberGenerator.new()

func select_random(array):
	return array[index_random(array)]

func index_random(array):
	return rng.randi() % len(array)

func select_random_and_remove(array):
	array = array.duplicate()
	var index = index_random(array)
	var selection = array[index]
	array.remove(index)
	return selection

func select_remaining(array, item):
	array = array.duplicate()
	array.erase(item)
	assert(len(array)==1)
	return array[0]

# Subtract all members in the used array from the unused array
# Then pick a random item from the unused array
func select_random_or_remaining(used_array, unused_array):
	used_array = used_array.duplicate()
	unused_array = unused_array.duplicate()
	for item in used_array:
		if unused_array.has(item):
			unused_array.erase(item)
	if len(unused_array) == 0:
		return null
	return select_random(unused_array)
