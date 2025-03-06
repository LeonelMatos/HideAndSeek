extends CharacterBody3D
class_name Player

## Group: Player Movement-------------------------------------------------------
@export_group("Movement")
##Default player's walking speed. [br][i](Default: 5)[/i]
##[br]Minimum speed is [b]5.0[/b] to avoid player stuck.
@export var DEFAULT_SPEED: float = 5.0:
	set(value): DEFAULT_SPEED = maxf(1, value)

##Velocity of player's jump. [br][i](Default: 6)[/i]
@export var JUMP_VELOCITY: float = 6.0:
	set(value): JUMP_VELOCITY = maxf(0, value)

##Value considered for the player to be below the level.
@export var below_map_y: float = -10

##Variable speed set at walking speed, changeable to running and back
var SPEED = DEFAULT_SPEED

##State of camera FOV if expanded or not due to running
## true if expanded for running, false if default
var is_running: bool = false:
	set(value):
		is_running = value
		if(is_running): await slide_cam_fov(1)
		else: await slide_cam_fov(-1)

## Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2

## Group: Player Parts----------------------------------------------------------
@export_group("Body Parts")
## Rotation base pivot for the camera.
@export var neck: Node3D:
	set(value): 
		if(!value): push_error("Player: Missing player neck in Player node")
		else: neck = value
## Main scene's camera for player.
@onready var camera := $Pivot/Camera3D

#region Lifecycle Methods
#--------------------------------------------------------------------------------

func _unhandled_input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			mouse_look(event)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	

func _physics_process(delta):
	handle_gravity(delta)
	if Input.is_action_pressed("run"):
		enable_run()
	elif Input.is_action_just_released("run") or (velocity.x == 0 or velocity.z == 0):
		disable_run()
	handle_movement()
	move_and_slide()
	handle_below_map()
#endregion

#region Movement Behaviour
#-------------------------------------------------------------------------------

func mouse_look(event: InputEventMouseMotion) -> void:
	neck.rotate_y(-event.relative.x * 0.003)
	camera.rotate_x(-event.relative.y * 0.003)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func enable_run() -> void:
	if !is_running and (velocity.x != 0 or velocity.z != 0):
		SPEED *= 2
		is_running = true

func disable_run() -> void:
	if is_running:
		SPEED = DEFAULT_SPEED
		is_running = false

func handle_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
#endregion
#region Camera Extra Controls
#-------------------------------------------------------------------------------
func slide_cam_fov(positive: int) -> void:
	for n in 20:
		camera.fov += 0.5 * positive
		await get_tree().create_timer(0.005).timeout

func get_cam_fov() -> float:
	return camera.fov
#endregion

#region Edge Cases
#-------------------------------------------------------------------------------
func handle_below_map() -> void:
	if global_position.y < below_map_y:
		global_position.y = 50.0
		print("Player fell from the map. Check for out of bounds leak on ", global_position)
