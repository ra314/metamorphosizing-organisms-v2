extends Node2D

var organisms
var pname
var game

var max_HP = 80
var curr_HP = max_HP
var max_berries = 4
var berries = 0

var is_player_two = false

func init(_pname):
	self.organisms = [$Organism1, $Organism2]
	for organism in organisms:
		add_child(organism)
		organism.connect("evolving_end", self, "consume_all_berries")
		organism.connect("boost", self, "boost")
	self.pname = _pname
	update_ui()
	return self

# Called by Level Main if this player is Player 2
func flip_ui():
	is_player_two = true
	
	var health_control := $Health_Control as Control
	var berry_control := $Berry_Control as Control
	
	# Flip the controls horizontally
	health_control.rect_scale *= Vector2(-1, 1)
	berry_control.rect_scale *= Vector2(-1, 1)
	
	var health_bar := $Health_Control/Health_Bar as Sprite
	var health_icon := $Health_Control/Health_Icon as Sprite
	
	var berry_bar := $Berry_Control/Berry_Bar as Sprite
	var berry_icon := $Berry_Control/Berry_Icon as Sprite
	
	health_bar.scale *= Vector2(-1, 1)
	health_icon.scale *= Vector2(-1, 1)
	
	berry_bar.scale *= Vector2(-1, 1)
	berry_icon.scale *= Vector2(-1, 1)
	
	var health_text := $Health_Control/Health/Text as RichTextLabel
	var berry_text := $Berry_Control/Berry/Text as RichTextLabel
	
	health_text.rect_scale *= Vector2(-1, 1)
	berry_text.rect_scale *= Vector2(-1, 1) 
	
func consume_all_berries():
	change_berries(-berries)

signal boost_end
signal boost_start
func boost(organism):
	emit_signal("boost_start")
	consume_all_berries()
	organism.change_mana(max_berries)
	# Waiting for 1 second so that the animation is clear
	yield(get_tree().create_timer(1), "timeout")
	emit_signal("boost_end")

func change_HP(delta):
	# Clamping health
	# The max of current and max hp is done in the case of the start where p2 has 5 extra HP
	curr_HP = clamp(curr_HP + delta, 0, max(max_HP, curr_HP))
	tween_HP(delta)
	update_ui()

const HEALTH_ICON_SCALE = Vector2(1,1) * 0.52
const INDICATOR_ICON_SCALE = Vector2(1,1) * 1.015
func tween_HP(delta):
	$Tween.reset_all()
	# Animation for the damage indicator
	var indicator := get_node("Indicator") as Control
	var num := get_node("Indicator/Number") as RichTextLabel
	var type := get_node("Indicator/Type") as RichTextLabel
	
	num.text = str(delta)
	
	if delta > 0:
		num.add_color_override("default_color", Color.green)
		type.text = "HEAL"
	else:
		num.add_color_override("default_color", Color.red)
		type.text = "DMG"
	
	# Reset the values before the animation
	indicator.rect_scale = INDICATOR_ICON_SCALE
	indicator.modulate = Color.white
	
	$Tween.interpolate_property(indicator, "rect_scale", indicator.rect_scale * 2, indicator.rect_scale, 1, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.interpolate_property(indicator, "modulate", indicator.modulate, Color.transparent, 2, Tween.TRANS_BACK, Tween.EASE_OUT, 2)
	
	# Animation for the health icon to pulse a bit
	
	var health_icon := get_node("Health_Control/Health_Icon") as Sprite
	var health_text := get_node("Health_Control/Health/Text") as RichTextLabel
	
	# Resets the values before the animation
	health_icon.scale = HEALTH_ICON_SCALE
	if is_player_two:
		health_icon.scale *= Vector2(-1, 1)
		
	health_text.modulate = Color.white
	
	$Tween.interpolate_property(health_icon, "scale", health_icon.scale * 2, health_icon.scale, 1, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	
	if delta > 0:
		$Tween.interpolate_property(health_text, "modulate", Color.green, health_text.modulate, 1, Tween.TRANS_BACK, Tween.EASE_OUT)
	elif delta < 0:
		$Tween.interpolate_property(health_text, "modulate", Color.red, health_text.modulate, 1, Tween.TRANS_BACK, Tween.EASE_OUT)
		
	$Tween.start()
	
const BERRY_ICON_SCALE = Vector2(1,1) * 0.52
func change_berries(delta):
	# Clamping berries
	var prev_berries = berries
	berries = clamp(berries + delta, 0, max_berries)
	
	if delta != 0:
		# Animation for the berry icon to pulse a bit
		
		var berry_icon := get_node("Berry_Control/Berry_Icon") as Sprite
		var berry_text := get_node("Berry_Control/Berry/Text") as RichTextLabel
		
		berry_icon.scale = BERRY_ICON_SCALE
		if is_player_two:
			berry_icon.scale *= Vector2(-1, 1)
		
		$Tween.interpolate_property(berry_icon, "scale", berry_icon.scale * 2, berry_icon.scale, 1, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		$Tween.start()
		
		if delta > 0:
			$Tween.interpolate_property(berry_text, "modulate", Color.green, berry_text.modulate, 1, Tween.TRANS_BACK, Tween.EASE_OUT)
		elif delta < 0:
			$Tween.interpolate_property(berry_text, "modulate", Color.red, berry_text.modulate, 1, Tween.TRANS_BACK, Tween.EASE_OUT)
	
	update_ui()
	# Returning the amount change in berries
	return abs(berries - prev_berries)
	
func update_ui(show_berries=false):
	$Health_Control/Health/Text.text = str(curr_HP)
	$Berry_Control/Berry/Text.text = str(berries) + "/" + str(max_berries)
	if berries == max_berries and show_berries and game.is_current_player():
		for organism in organisms:
			organism.show_berry_actions()
	else:
		for organism in organisms:
			organism.hide_berry_actions()

func is_full_of_mana():
	return organisms[0].is_full_of_mana() and organisms[1].is_full_of_mana()
