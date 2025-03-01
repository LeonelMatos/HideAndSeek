class_name Player
extends CharacterBody3D

# Player Movement
#Constant set default when walking. Saved when needed to return to
const DEFAULT_SPEED = 5.0
const JUMP_VELOCITY = 6

#Variable speed set at walking speed, changeable to running and back
var SPEED = DEFAULT_SPEED

#State of camera FOV if expanded or not due to running
#true if expanded for running, false if default
var is_running: bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2

# Rotation base pivot for the camera
@onready var neck := $Pivot
@onready var camera := $Pivot/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.003)
			camera.rotate_x(-event.relative.y * 0.003)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# RUN
	if Input.is_action_pressed("run"):
		if !is_running and (velocity.x != 0 or velocity.z != 0): #incr fov
			SPEED *= 2
			is_running = true
			await slide_cam_fov(1)
	elif Input.is_action_just_released("run") or (velocity.x == 0 or velocity.z == 0):
		if is_running: #decr fov
			SPEED = DEFAULT_SPEED
			is_running = false
			await slide_cam_fov(-1)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func slide_cam_fov(positive: int) -> void:
	for n in 20:
			camera.fov += 0.5 * positive
			await get_tree().create_timer(0.005).timeout

func get_cam_fov() -> float:
	return camera.fov
