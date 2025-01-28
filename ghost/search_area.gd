extends Node3D

class_name SearchArea

## Ghost Director
@export var director: GhostDirector

## Debug sphere of the ghost's range
@onready var mesh: MeshInstance3D

## Range of the ghost's search, must be greater than 0
@export_range(1,50,1,"or_greater") var search_range: float = 10:
	set(value): 
		search_range = maxf(1,value) 

##Minimum of nodes accepted to return the selected nodes.
##If number of search nodes found is less, we increase the search area to find more.
@export var min_nodes_accepted: int = 3:
	set(value):
		min_nodes_accepted = maxi(3,value) #Two or less will cause problems

##Check if there are too many nodes in a search range area.
##Useful to detect areas where the ghost might be stuck or spend more time
@export var max_nodes_accepted: int = 10:
	set(value):
		max_nodes_accepted = maxi(1,value)

func _ready():
	assert(director)
	mesh = get_node("DebugMesh") as MeshInstance3D
	mesh.visible = false
	randomize()

func set_range(rng: float) -> void:
	search_range = rng

## Finds nodes children of GhostDirector near the ghost by range
func find_nodes() -> Array[SearchNode]:
	#Array of selected nodes
	#New array created each second? Might cause memory problem,
	#But it's small arrays
	var searchNodes: Array[SearchNode] = []
	#Position of the SearchArea
	var origin = self.global_transform.origin
	var node_pos: Vector3
	var distance: float
	#Initial value is search_range, then increments by 10 each attempt
	var rng: float = search_range
	while searchNodes.size() < min_nodes_accepted:
		mesh.scale = Vector3(rng, rng, rng)
		for node in director.get_children():
			if node is SearchNode:
				node_pos = node.global_transform.origin
				distance = origin.distance_to(node_pos)
				if distance <= rng:
					searchNodes.append(node)
		rng += 10.0
	if searchNodes.size() > max_nodes_accepted:
		printerr("Search: Too many search nodes in this area. Please remove some at", origin)
	searchNodes.shuffle() #Garantees randomness without tree structure
	return searchNodes

# Enable/Disable debug view of the search area
#NOTE updated to also receive status of debug, may cause unhandled errors
func _on_game_manager_debug(status: bool):
	assert(mesh)
	if status:
		mesh.scale = Vector3(search_range, search_range, search_range)
		mesh.visible = true
	else:
		mesh.visible = false
