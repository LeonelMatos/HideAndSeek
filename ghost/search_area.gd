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

func _ready():
	assert(director)
	mesh = get_node("DebugMesh") as MeshInstance3D
	mesh.visible = false

func set_range(rng: float) -> void:
	search_range = rng

## Finds nodes children of GhostDirector near the ghost by range
func find_nodes() -> Array[SearchNode]:
	#Array of selected nodes
	var searchNodes: Array[SearchNode] = []
	#Position of the SearchArea
	var origin = self.global_transform.origin
	var node_pos: Vector3
	var distance: float
	#Initial value is search_range, then increments by 10 each attempt
	var rng: float = search_range
	while searchNodes.size() < 2:
		for node in director.get_children():
			if node is SearchNode:
				node_pos = node.global_transform.origin
				distance = origin.distance_to(node_pos)
				if distance <= rng:
					searchNodes.append(node)
		rng += 10.0
	return searchNodes

# Enable/Disable debug view of the search area
func _on_game_manager_debug():
	if director.active_search:
		assert(mesh)
		if !mesh.visible:
			mesh.scale = Vector3(search_range, search_range, search_range)
			mesh.visible = true
			print("Correctly set the mesh scale")
		else:
			mesh.visible = false
