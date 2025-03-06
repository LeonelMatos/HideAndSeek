extends CharacterBody3D
class_name Enemy

## Emitted when the enemy changes its searching state
signal on_searching_change(value: bool)

## Group: Navigation ----------------------------------------------------------
@export_group("Navigation")
@export var nav_region: NavigationRegion3D
## The [b]Enemy Director[/b] is responsible of controlling this enemy's navigation
## and search functions.
@export var director: EnemyDirector

@onready var nav: NavigationAgent3D = $NavigationAgent3D

## Group: Search --------------------------------------------------------------
@export_group("Search")
## Maximum distance to consider player nearby
@export var close_distance: float = 10.0:
	set(value): close_distance = maxf(0, value)
## Rotation speed when facing nearby player
@export var turn_speed: float = 5.0:
	set(value): turn_speed = maxf(1.0, value)

## Group: Spawn ----------------------------------------------------------------
@export_group("Spawn")
## Possible initial spawn positions list for this enemy using [Vector3] positions.
@export var starting_seek_positions: Array[Vector3] = [
	Vector3(70, 1, 60), 
	Vector3(-17, 1, -10)
]
## Accepted threshold distance from the player's position to spawn the enemy
##from the [param starting_seek_positions] array.
@export var spawn_distance: int = 10

## Group: Movement ------------------------------------------------------------
@export_group("Movement")
## [b]Base movement speed[/b] in meters/second [i](default: 4.0)[/i]
## [color=yellow]Adjust based on enemy type
@export var speed: float = 4.0
## Movement acceleration.
@export var acceleration: float = 10.0
## Time [i](in seconds)[/i] before detecting stuck state.
@export var stuck_detection_time: float = 5.0

# Node references
@onready var player: Player = get_tree().get_first_node_in_group("Player") as Player:
	set(value):
		if !value:
			push_error("Missing player node in scene")
		player = value
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var slide_sound: AudioStreamPlayer3D = $SlideAppear

# State management
var is_searching: bool = false:
	set(value):
		is_searching = value
		on_searching_change.emit(value)
		director.set_active_search(value)

var ready_nav: bool = false
var player_inside: bool = false
var last_position: Vector3 = Vector3.ZERO
var stuck_timer: Timer = null

#region Lifecycle Methods
#--------------------------------------------------------------------------------
func _ready() -> void:
	nav.set_physics_process(false)
	call_deferred("initialize_navigation")
	randomize()
	on_searching_change.connect(director._on_searching_change)
	spawn_enemy()

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	
	if is_player_near():
		follow_player()
#endregion

#region Navigation & Movement
#--------------------------------------------------------------------------------
func initialize_navigation() -> void:
	"""Initialize navigation system after scene setup"""
	await get_tree().physics_frame
	nav.set_physics_process(true)
	nav.target_position = player.global_position
	ready_nav = true
	nav.target_reached.connect(_on_target_reached)

func handle_movement(delta: float) -> void:
	"""Main movement handling function"""
	if not is_searching:
		return
	var target_position: Vector3 = nav.get_next_path_position()
	var move_direction: Vector3 = (target_position - global_position).normalized()
	
	velocity = velocity.lerp(move_direction * speed, acceleration * delta)
	
	if not nav.is_target_reached():
		move_and_slide()
	update_rotation(delta)

func update_rotation(delta: float) -> void:
	"""Handle rotation logic based on current state"""
	if is_player_near():
		face_target(player.global_position, delta)
	else:
		face_target(nav.target_position, delta)

func face_target(target: Vector3, delta: float) -> void:
	"""Smoothly rotate towards a target position"""
	var flat_target := Vector3(target.x, global_position.y, target.z)
	var target_direction := (flat_target - global_position).normalized()
	rotation.y = lerp_angle(rotation.y, atan2(-target_direction.x, -target_direction.z), turn_speed * delta)

func move_to_next_node() -> void:
	nav.target_position = director.get_next_node_pos()
#endregion

#region Spawn & Appearance
#--------------------------------------------------------------------------------
func spawn_enemy() -> void:
	"""Spawn enemy at random starting position"""
	assert(starting_seek_positions.size() > 0, "Need at least one starting position")
	assert(director != null, "Missing EnemyDirector reference")
	var spawn_index: int
	var player_position: Vector3 = player.global_position
	var valid_spawn: bool = false
	
	while !valid_spawn:
		spawn_index = randi() % starting_seek_positions.size()
		var spawn_candidate = starting_seek_positions[spawn_index] + Vector3.DOWN * 5
		if player_position.distance_to(spawn_candidate) > spawn_distance:
			global_position = spawn_candidate
			valid_spawn = true
			
	slide_sound.play()
	await animate_spawn(1.0)
	
	is_searching = true
	nav_region.enabled = true
	
	nav.target_position = director.get_first_node_pos()
	initialize_stuck_detection()

func animate_spawn(direction: float) -> void:
	"""Animate enemy spawn/hide sequence"""
	if absf(direction) != 1.0:
		push_error("Invalid slide direction: must be 1 or -1")
		return
	
	collision_shape.disabled = true
	nav.set_physics_process(false)
	
	for _i in 20:
		position.y += 0.15 * direction
		await get_tree().create_timer(0.01).timeout
	
	collision_shape.disabled = false
	nav.set_physics_process(true)
#endregion

#region Player Detection
#--------------------------------------------------------------------------------
func is_player_near() -> bool:
	"""Check if player is within detection range"""
	return global_position.distance_to(player.global_position) <= close_distance

func follow_player() -> void:
	"""Change path to follow player"""
	nav.target_position = player.global_position

func _on_3d_body_entered(body: Node3D) -> void:
	"""Handle player entering detection area"""
	if body is Player:
		player_inside = true

func _on_3d_body_exited(body: Node3D) -> void:
	"""Handle player exiting detection area"""
	if body is Player:
		player_inside = false
#endregion

#region State Management
#--------------------------------------------------------------------------------
func _on_main_timer_timeout() -> void:
	"""Handle search state timeout"""
	is_searching = false
	if not is_searching:
		nav_region.enabled = false
		stop_stuck_detection()
		slide_sound.play()
		await animate_spawn(-1.0)

func initialize_stuck_detection() -> void:
	"""Setup stuck detection system"""
	if stuck_timer:
		stuck_timer.queue_free()
	
	stuck_timer = Timer.new()
	stuck_timer.wait_time = stuck_detection_time
	stuck_timer.timeout.connect(_on_stuck_timeout)
	add_child(stuck_timer)
	stuck_timer.start()

func stop_stuck_detection() -> void:
	"""Clean up stuck detection system"""
	if stuck_timer and stuck_timer.is_inside_tree():
		stuck_timer.stop()
		stuck_timer.queue_free()
		stuck_timer = null

func _on_stuck_timeout() -> void:
	"""Handle stuck detection timeout"""
	if is_stuck():
		print_debug("Enemy stuck - recalculating path")
		nav.target_position = director.get_next_node_pos()

func is_stuck() -> bool:
	"""Check if enemy hasn't moved significantly"""
	var current_position := global_position
	var stuck: bool = current_position.distance_to(last_position) < 0.1
	last_position = current_position
	return stuck
#endregion

#region Navigation Callbacks
#--------------------------------------------------------------------------------
func _on_target_reached() -> void:
	"""Handle navigation target reached event"""
	print_debug("Navigation target reached")
	nav.target_position = director.get_next_node_pos()
#endregion

#region Game Logic
#--------------------------------------------------------------------------------
func _on_game_manager_debug(status: bool):
	nav.debug_enabled = status
#endregion
