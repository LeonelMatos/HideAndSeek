extends Node
class_name GhostDirector

##Used of debug mode
@export var game_manager: Node

##Area3D on the ghost to detect searchNodes
@export var search_area: SearchArea

##Defines when the search_area is active to find nodes. Should only be when ghost searchs
var active_search: bool = false

#Active search nodes that the ghost will use to wander or search
var selected_nodes: Array[SearchNode] = []

#Gets all the names of all search_nodes in an array
func get_nodes_name(group: Array[SearchNode]) -> Array[String]:
	var arr: Array[String] = []
	for node in group:
		arr.append(node.name)
	if arr.is_empty():
		arr.append("empty")
	return arr

func _ready():
	#Checks
	if !search_area:
		printerr("SearchGroup: search_area not defined in editor")
	#Hide debug nodes on runtime for runtime? weird flex
	#TODO hide debug nodes before entering runtime maybe
	for child in get_children():
		if child is SearchNode:
			child.visible = false 
	#search_area.set_range(search_range)
	refresh_search_area()

#TODO maybe refresh only when the ghost finished arriving at the previous/current node
func refresh_search_area() -> void:
	while active_search:
		await get_tree().create_timer(5.0).timeout
		selected_nodes = search_area.find_nodes()
		game_manager.set_director_debug_text(active_search, selected_nodes.size())

#Returns a random node from the selected search nodes
func get_random_node() -> SearchNode:
	var rnd = randi_range(0, selected_nodes.size()-1)
	return selected_nodes[rnd]

#Signal from gamemanager
func _on_game_manager_debug():
	for child in get_children():
		if child is SearchNode:
			child.visible = not child.visible

#Converts an array of strings to a string. With optional separator
func array_to_string(arr: Array[String], separator: String = "\n") -> String:
	var s = ""
	for i in arr:
		s += String(i) + separator
	return s

#Call from ghost to tell when it's searching
func _on_ghost_on_searching_change(value):
	active_search = value
	#Refreshes and saves the selected nodes
	if active_search == true:
		refresh_search_area()
