extends Node
class_name EnemyDirector

##Used of debug mode
@export var game_manager: Node

var current_enemies: Dictionary = {}

#Gets all the names of all search_nodes in an array
func get_nodes_name(group: Array[SearchNode]) -> Array[String]:
	var arr: Array[String] = []
	for node in group:
		arr.append(node.name)
	if arr.is_empty():
		arr.append("empty")
	return arr

func _ready() -> void:
	randomize()
	if get_child_count() < 1:
		printerr("Missing child nodes SearchNodes from the EnemyDirector")
	for child in get_children():
		if child is SearchNode:
			child.visible = false

##Calls search_area to give and return the active nodes to use
##Only called when needed, returns selected_nodes in array
func refresh_search_area(search_area: SearchArea) -> Array[SearchNode]:
	if !current_enemies.has(search_area.get_enemy_name()):
		current_enemies[search_area.get_enemy_name()] = search_area
	game_manager.set_director_debug_text(current_enemies.size())
	return search_area.find_nodes()
	#game_manager.set_director_debug_text(active_search, selected_nodes.size()) TODO update text debug

##Returns a random node from all nodes
##Useful for the enemy's first time getting nodes
func get_first_node_pos() -> Vector3:
	var rnd: int = randi_range(0, get_child_count()-1)
	var node: SearchNode = get_child(rnd) as SearchNode
	return node.global_position

#Returns a random node from the selected search nodes
#Note that it returns a random from within distance, not all
func get_random_node_pos(search_area: SearchArea) -> Vector3:
	var selected_nodes: Array[SearchNode] = refresh_search_area(search_area)
	if selected_nodes.is_empty():
		printerr("Group: Can't select random node because selected_nodes is empty")
		return Vector3.ZERO
	#BUG second random after get_nodes in search area already shuffles the selected nodes
	var rnd = randi_range(0, selected_nodes.size()-1)
	#print("Group: Selected random node: ", rnd)
	search_area.add_old_node(selected_nodes[rnd])
	return selected_nodes[rnd].global_position

#Pondered node returned considering parameters
#Can't be the same node that the ghost is in and can't be the previous few nodes
#Same node should be added to the old nodes and exclude old nodes from the search
func get_next_node_pos(search_area: SearchArea) -> Vector3:
	var selected_nodes: Array[SearchNode] = refresh_search_area(search_area)
	if selected_nodes.is_empty():
		printerr("Group: Can't select random node because selected_nodes is empty")
		return Vector3.ZERO
	#Maximum number of attempts to find a new unused node
	var max_attempts: int = selected_nodes.size()
	var attempt: int = 0
	while attempt < max_attempts:
		#Won't use random. Doing by n attempt will not repeat same node like rnd does
		#var rnd: int = randi_range(0,selected_nodes.size()-1)
		var node: SearchNode = selected_nodes[attempt]
		if !search_area.is_node_old(node):
			search_area.add_old_node(node)
			return node.global_position
		attempt += 1
	#There aren't valid new nodes, --falling back to previous used node--
	printerr("No valid new node found. Expanding search ")
	#Just picks one old. Bad choice, I want to expand the range
	var fall_node: SearchNode = selected_nodes[randi_range(0, selected_nodes.size()-1)]
	search_area.add_old_node(fall_node)
	return fall_node.global_position

#Signal from gamemanager. Toggle SearchNodes visibility
func _on_game_manager_debug(status: bool):
	for child in get_children():
		if child is SearchNode:
			child.visible = status

func remove_current_enemy(enemy_name: String) -> void:
	if current_enemies.has(enemy_name):
		current_enemies.erase(enemy_name)

#Converts an array of strings to a string. With optional separator
func array_to_string(arr: Array[String], separator: String = "\n") -> String:
	var s = ""
	for i in arr:
		s += String(i) + separator
	return s
