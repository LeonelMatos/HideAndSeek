extends Node3D

class_name SearchArea

@onready var area = $Area3D
@onready var collision = $Area3D/CollisionShape3D
@onready var mesh = $Area3D/MeshInstance3D

@export var shape_close: SphereShape3D
@export var shape_medium: SphereShape3D
@export var shape_far: SphereShape3D

func set_range(rng: int) -> void:
	if rng < 0 or rng > 2:
		printerr("SearchArea: range must be between 0 and 2")
		pass
	match rng:
		0:
			collision.shape = shape_close
		1:
			collision.shape = shape_medium
		2:
			collision.shape = shape_far
		
	mesh.scale = Vector3(rng, rng, rng)
	
func find_nodes() -> Array[SearchNode]:
	var searchNodes: Array[SearchNode] = []
	var bodies: Array[Node3D] = area.get_overlapping_bodies()
	for body in bodies:
		if body is SearchNode:
			searchNodes.append(body)
	return searchNodes

#TODO FUCKING IMPORTANT!! When scaling search_area node it doesn't increase the area 3d dummy
#Specificaly increase the collisionShape and the MeshInstance
