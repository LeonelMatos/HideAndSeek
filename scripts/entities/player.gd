extends CharacterBody3D
class_name Player

## Group: Player Movement-------------------------------------------------------
@export_group("Movement")
##Default player's walking speed. [br][i](Default: 5)[/i]
##[br]Minimum speed is [b]5.0[/b] to avoid player stuck.
@export var DEFAULT_SPEED: float = 5.0:
	set(value): DEFAULT_SPEED = maxf(1, value)

@export_subgroup("Jump")
##Velocity of player's jump. [br][i](Default: 6)[/i]
@export var JUMP_VELOCITY: float = 6.0:
	set(value): JUMP_VELOCITY = maxf(0, value)

@export_subgroup("Crouch")
##Speed multiplier when crouching.
@export var CROUCH_SPEED_MULT: float = 0.5

@export var CROUCH_HEIGHT: float = 1.3

@export var STAND_HEIGHT: float = 2.0

@export var crouch_smoothing: float = 0.1

@export_subgroup("Camera")
@export var camera_sensitivity: float = 0.003

@export_subgroup("Fall")
##Value considered for the player to be below the level.
@export var below_map_y: float = -40

##Variable speed set at walking speed, changeable to running and back.
var SPEED: float = DEFAULT_SPEED

##State of crouching.
var is_crouching: bool = false

##Target height for smooth crouch transition.
var target_height: float = STAND_HEIGHT

##State of camera FOV if expanded or not due to running
## true if expanded for running, false if default.
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

@export var hand: Node3D

# Group: Flashlight-------------------------------------------------------------
@export var flashlight: SpotLight3D
var target_flashlight_rotation: Vector3 = Vector3.ZERO
var flashlight_smoothing: float = 0.07

#region Lifecycle Methods
#-------------------------------------------------------------------------------

func _unhandled_input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			mouse_look(event)
			flashlight_handle(event)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("toggle_flash"):
		flashlight.toggle_flashlight()

func _physics_process(delta):
	handle_gravity(delta)
	handle_crouch()
	if Input.is_action_pressed("run") and !is_crouching:
		enable_run()
	elif Input.is_action_just_released("run") or (velocity.x == 0 or velocity.z == 0):
		disable_run()
	handle_movement()
	move_and_slide()
	handle_below_map()

func _process(_delta: float) -> void:
	#Flashlight
	flashlight.rotation.x = lerp(flashlight.rotation.x, target_flashlight_rotation.x, flashlight_smoothing)
	hand.rotation.y = lerp(hand.rotation.y, target_flashlight_rotation.y, flashlight_smoothing)
	#Crouch
	scale.y = lerp(scale.y, target_height / STAND_HEIGHT, crouch_smoothing)
	hand.position.y = lerp(hand.position.y, target_height-1.5, crouch_smoothing)
#endregion

#region Movement Behaviour
#-------------------------------------------------------------------------------
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
		velocity.x = direction.x * SPEED * (CROUCH_SPEED_MULT if is_crouching else 1.0)
		velocity.z = direction.z * SPEED * (CROUCH_SPEED_MULT if is_crouching else 1.0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func handle_crouch() -> void:
	if Input.is_action_pressed("crouch"):
		if !is_crouching:
			is_crouching = true
			target_height = CROUCH_HEIGHT
			SPEED *= CROUCH_SPEED_MULT
			if randf() <= 0.1:
				var knee_joits: AudioStreamPlayer3D = find_child("Knees")
				knee_joits.play()
	else:
		if is_crouching:
			is_crouching = false
			target_height = STAND_HEIGHT
			SPEED = DEFAULT_SPEED

#endregion
#region Camera Extra Controls
#-------------------------------------------------------------------------------
func mouse_look(event: InputEventMouseMotion) -> void:
	neck.rotate_y(-event.relative.x * camera_sensitivity)
	camera.rotate_x(-event.relative.y * camera_sensitivity)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func flashlight_handle(event: InputEventMouseMotion) -> void:
	target_flashlight_rotation.y -= event.relative.x * camera_sensitivity
	target_flashlight_rotation.x -= event.relative.y * camera_sensitivity
	target_flashlight_rotation.x = clamp(target_flashlight_rotation.x, deg_to_rad(-89), deg_to_rad(89))

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
		velocity = Vector3.ZERO
		print("Player fell from the map. Check for out of bounds leak on ", global_position)
