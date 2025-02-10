extends Label

# Declares which turn is, find=false/hide=true, then alternates
#Next time the function will be called will go from find to hide, so
#it's already set on true
var game_turn: bool = true

func _ready():
	#await text_fade_out("Find the ghost")
	pass

func _on_ghost_found():
	await text_fade_out(ghost_found_lst.pick_random())

func _on_main_timer_timeout():
	if game_turn:
		await text_fade_out(hide_lst.pick_random())
	else:
		await text_fade_out(find_lst.pick_random())
	game_turn = !game_turn

func text_fade_out(txt: String):
	text = txt
	var color = Color(1, 1, 1, 1)
	#await get_tree().create_timer(1).timeout
	for n in 50:
		color.a -= 0.02
		self.modulate = color
		await get_tree().create_timer(0.05).timeout

var ghost_found_lst: Array = [ \
"Ghost found" \
	 ]

#TODO Deprecated
var find_lst: Array = [ \
	"Find the ghost", \
	"Look for the soul", \
	"Seek death", \
	"Search out the ghost"
	 ]

var hide_lst: Array = [ \
	"Hide", \
	"Run away and cover", \
	"Find a hiding spot", \
	"Hide or die"
	 ]
