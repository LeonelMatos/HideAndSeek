extends CharacterBody3D
class_name Enemy

@onready var player: Player

# Navigation
@export_group("Navigation")
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@export var nav_region: NavigationRegion3D
@export var director: EnemyDirector

# Says when navigation is ready after setting up
var ready_nav: bool = false

# Indicates when it's the enemy's turn to seek
var is_searching: bool = true

# Signal for other scripts to update their is_searching value
signal on_searching_change(value)

@export_group("Search")
## Distance at which the player is close to the enemy
@export var close_distance: float = 10.0:
	set(x): close_distance = maxf(0,x)

## Speed of turning to face the player when nearby
@export var turn_speed: float = 5.0:
	set(x): turn_speed = maxf(1.0,x)

# Set the begin location of the enemy for seeking
var starting_seek_position = [
	Vector3(70,1,60), Vector3(-17,1,-10)
]

# Check if player is inside the trigger box
var player_inside: bool = false

@export_group("Movement")
## Set speed of chasing enemy used on physics process
@export var speed = 4
## Acceleration of chasing enemy used on physics process
@export var accel = 10

# Edge case if enemy is stuck in same position, tracking
var last_position: Vector3 = Vector3.ZERO
var stuck_timer: Timer
## Time before deciding if the enemy is stuck in position
@export var stuck_detection: float = 5.0

func _ready():
	nav.set_physics_process(false)
	# Called on first frame, loads on next to avoid conflict
	call_deferred("nav_setup")
	randomize() #seed
	player = get_tree().get_first_node_in_group("Player")
	spawn_enemy()

func _process(_delta):
	pass

# Load after first frame (map syncronization loading on runtime)
#https://github.com/godotengine/godot/issues/84677
func nav_setup():
	await get_tree().physics_frame
	nav.set_physics_process(true)
	nav.target_position = player.global_position
	ready_nav = true
	# Connect the signal of target reached to the ghost
	nav.connect("target_reached", Callable(self, "_on_target_reached"))

# Calculate ghost's navigation
func _physics_process(delta):
	var direction = Vector3()
	if is_searching:
		direction = nav.get_next_path_position() - global_position
		direction = direction.normalized()
		velocity = velocity.lerp(direction * speed, accel * delta)
		if !nav.is_target_reached():
			move_and_slide()
		if is_player_near():
			look_at_player(delta)
			#TODO Stop active searching when finding player
			#Maybe stop the timer that refreshes the search nodes
			#And start it when ghost loses the player
			nav.target_position = player.global_position
		else:
			look_at_target()
	#Not searching
	else:
		if is_player_near():
			look_at_player(delta)

# Moves the enemy to a random spawn
func spawn_enemy() -> void:
	var rnd = randi_range(0, starting_seek_position.size()-1)
	position = starting_seek_position[rnd]
	position.y -= 5
	get_node("SlideAppear").play()
	await enemy_appear_slide(1)
	nav_region.enabled = true
	#Nav search. First movement direction, nav will keep going on _on_target_reached
	if !ready_nav:
		printerr("Enemy: navigation not ready when defining target")
	nav.target_position = director.get_first_node_pos()
	init_stuck_timer()

func look_at_target():
	var target_position_flat: Vector3 = Vector3(nav.target_position.x,global_position.y,nav.target_position.z)
	look_at(target_position_flat)

# Enemy looks at player when he's near
func look_at_player(delta) -> void:
	if is_player_near():
		var player_position_flat: Vector3 = Vector3(player.global_position.x,global_position.y,player.global_position.z)
		var player_direction: Vector3 = (player_position_flat - global_position).normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-player_direction.x, -player_direction.z), turn_speed * delta)

func is_player_near() -> bool:
	return position.distance_to(player.position) <= close_distance

# Trigger box of ghost area3D node with collided body (player)
func _on_3d_body_entered(coll_body):
	if coll_body is Player:
		player_inside = true

func _on_3d_body_exited(coll_body):
	if coll_body is Player:
		player_inside = false

# Signal where navigation gets target
func _on_main_timer_timeout():
	is_searching = false
	on_searching_change.emit(is_searching)
	if !is_searching:
		nav_region.enabled = false
		stop_stuck_timer()
		get_node("SlideAppear").play()
		await enemy_appear_slide(-1)

func enemy_appear_slide(direction: int) -> void:
	if !is_searching:
		pass
	if absi(direction) != 1:
		printerr("Ghost: value direction should only be -1 or 1")
		return
	var collision = get_node("CollisionShape3D")
	collision.disabled = true
	nav.set_physics_process(false)
	for n in 20:
		position.y += 0.15 * direction #constant multiplier default: 0.01
		await get_tree().create_timer(0.01).timeout
	collision.disabled = false
	nav.set_physics_process(true)
	#NOTE may be bugged. skip if not searching
	#to avoid unexpected movement in hiding
	#it's not this. Can remove if needed


# NAVIGATION/PLAYER_SEARCH AUX FUNCTIONS

#Signal from nav agent when reached search node.
#Handles the ghost's behavior on how to proceed
func _on_target_reached():
	print("Enemy: reached target position")
	###TODO finish the behaviour
	nav.target_position = director.get_next_node_pos()

#Nav SearchNode reached option.
#TODO Will look around to search for the player
#Only when outside (more search space, less time wasted on closed spaces)
#Use !player_inside
func look_around_on_search() -> void:
	pass

#Nav SearchNode reached option.
#TODO Will wait for a moment to relax a bit, why not... should it?
func wait_on_search() -> void:
	pass

#Nav SearchNode reached option.
# Will move to the next nearby node. 
#TODO should ponder better on which node to go instead of random
#Change of deciding to go to a node with distance closer to player?
func move_to_next_node() -> void:
	nav.target_position = director.get_next_node_pos()

#NOTE updated to also receive status of debug, may cause unhandled errors
func _on_game_manager_debug(status: bool):
	nav.debug_enabled = status


# EDGE CASE: ENEMY STUCK

#Edge case to detect if ghost is stuck. Setup and Starts the timer
func init_stuck_timer():
	if stuck_timer:
		stuck_timer.queue_free()
	stuck_timer = Timer.new()
	stuck_timer.wait_time = stuck_detection
	stuck_timer.one_shot = false
	stuck_timer.connect("timeout", Callable(self, "_on_stuck_timer_timeout"))
	add_child(stuck_timer)
	stuck_timer.start()

# Stops and clears the stuck timer when not needed
func stop_stuck_timer():
	if stuck_timer and stuck_timer.is_inside_tree():
		stuck_timer.stop()
		stuck_timer.queue_free()
		stuck_timer = null

# End of timer on stuck position. Will check if stuck each stuck_detection time
func _on_stuck_timer_timeout():
	if is_enemy_stuck():
		printerr("Enemy: enemy hasn't moved for ", stuck_detection, "s. Changing path")
		nav.target_position = director.get_next_node_pos()

# Checks if the enemy's position hasn't changed
func is_enemy_stuck() -> bool:
	if global_position.distance_to(last_position) < 0.1:
		return true
	last_position = global_position
	return false
