extends Node3D

class_name SearchArea

@onready var area: Area3D = null
@onready var collision: CollisionShape3D = null
@onready var mesh: MeshInstance3D = null

@export var shape_close: SphereShape3D
@export var shape_medium: SphereShape3D
@export var shape_far: SphereShape3D

var scale_factors = [10.0, 20.0, 30.0]

func set_range(rng: int) -> void:
	collision = get_node("Area3D/CollisionShape3D") as CollisionShape3D
	mesh = get_node("Area3D/MeshInstance3D") as MeshInstance3D
	if rng < 0 or rng > scale_factors.size():
		printerr("SearchArea: range must be between 0 and 2")
		return
	if collision == null:
		printerr("SearchArea: collision or collision.shape invalid")
		return
	
	collision.disabled = true
	match rng:
		0:
			collision.shape = shape_close
		1:
			collision.shape = shape_medium
		2:
			collision.shape = shape_far
	collision.disabled = false

	var scale = scale_factors[rng]
	mesh.scale = Vector3(scale, scale, scale)
	print("SearchArea: search range updated")

func find_nodes() -> Array[SearchNode]:
	area = get_node("Area3D") as Area3D
	var searchNodes: Array[SearchNode] = []
	var bodies: Array[Node3D] = area.get_overlapping_bodies()
	for body in bodies:
		if body is SearchNode:
			searchNodes.append(body)
	return searchNodes

#TODO FUCKING IMPORTANT!! When scaling search_area node it doesn't increase the area 3d dummy
#Specificaly increase the collisionShape and the MeshInstance
