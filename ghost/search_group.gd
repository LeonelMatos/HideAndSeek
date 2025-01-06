extends Node
class_name GhostDirector

##Used of debug mode
@export var game_manager: Node

##Area3D on the ghost to detect searchNodes
@export var search_area: SearchArea

##Time of refresh on refresh_search_area. Must be positive
@export var refresh_time: float = 1.0:
	set(value): refresh_time = maxf(0.5,value)

##Defines when the search_area is active to find nodes. Should only be when ghost searchs
var active_search: bool = false

#Active search nodes that the ghost will use to wander or search
var selected_nodes: Array[SearchNode] = []

#Stores old nodes that were previously used by navigation. Memory of 3
var old_nodes: Array[SearchNode] = []

#Gets all the names of all search_nodes in an array
func get_nodes_name(group: Array[SearchNode]) -> Array[String]:
	var arr: Array[String] = []
	for node in group:
		arr.append(node.name)
	if arr.is_empty():
		arr.append("empty")
	return arr

func _ready():
	randomize()
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
		selected_nodes = search_area.find_nodes()
		print("Updated search area. Found ", selected_nodes.size(), " nodes")
		game_manager.set_director_debug_text(active_search, selected_nodes.size())
		await get_tree().create_timer(refresh_time).timeout

#Returns a random node from the selected search nodes
func get_random_node_pos() -> Vector3:
	if selected_nodes.is_empty():
		printerr("Group: Can't select random node because selected_nodes is empty")
		return Vector3.ZERO
	var rnd = randi_range(0, selected_nodes.size()-1)
	print("Group: Selected random node: ", rnd)
	return selected_nodes[rnd].global_position

#Pondered node returned considering parameters
#Can't be the same node that the ghost is in and can't be the previous few nodes
#Same node should be added to the old nodes and exclude old nodes from the search
func get_next_node_pos() -> Vector3:
	return Vector3.ONE

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
