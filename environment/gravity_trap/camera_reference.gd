extends MeshInstance3D


@onready var camera = $Camera3D  # Replace with your actual camera node path
@onready var material = $MeshInstance.material_override  # Replace with your shader material

func _process(_delta: float) -> void:
	if camera and material:
		material.set_shader_param("camera_position", camera.global_transform.origin)

