extends TextureRect

@onready
var arrow = $Arrow
@onready var elevation = $Elevation

@export var player_neck: Node3D
@export var target: Node3D

func _ready():
	if !player_neck or !target:
		printerr("Compass: player camera or target not defined in the inspector")
	elevation.visible = false

# Calculate the direction of the target in 2D (ignoring Y axis) 
func _process(_delta):
	var direction = (target.global_transform.origin - player_neck.global_transform.origin).normalized()
	var angle = atan2(direction.z, direction.x)
	arrow.rotation_degrees = rad_to_deg(angle) + 90 + player_neck.rotation_degrees.y
	
	#Distance in the y-axis between the player and the target
	var height_distance = player_neck.global_transform.origin.y - target.global_transform.origin.y
	if abs(height_distance) > 2:
		elevation.visible = true
		if height_distance < 0:
			elevation.flip_v = false
			
		else:
			elevation.flip_v = true
	else:
		elevation.visible = false

