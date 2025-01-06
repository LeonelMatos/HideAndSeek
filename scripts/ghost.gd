extends CharacterBody3D

signal ghost_found

@export var player: Player

#Navigation
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@export var nav_region: NavigationRegion3D
@export var director: GhostDirector

var ready_nav: bool = false

#Indicates when it's the ghost's turn to seek
#If GHOST is searching
#Starts at false for player's turn
var is_searching: bool = false

#Signal for other scripts to update their is_searching value
#it's a way to follow
signal on_searching_change(value)

# Matrix of spawn positions grouped by difficulty. Diff by Pos
var spawn_locations = [
	[Vector3(-1.5,0,8), Vector3(-5,0,32), Vector3(2.5,4.5,30),
	Vector3(-5.5,4.5,18), Vector3(9.5,4.5,9), Vector3(14.5,4.5,9),
	Vector3(17.5,0,8), Vector3(17.5,0,32), Vector3(4.5,0,33),
	Vector3(10.5,0,-14),Vector3(-10.5,0,-14), Vector3(-12.5,0,-12)], # Easy
	[Vector3(-2,0,0), Vector3(-4,0,0), Vector3(-6,0,0)], # Medium
]

## Distance at which the player is close to the ghost
var close_distance: float = 4.0

# Set the begin location of the ghost for seeking
var starting_seek_position = [
	Vector3(70,1,60), Vector3(-17,1,-10)
]

# Check if player is inside the trigger box
var player_inside: bool = false

## Set speed of chasing ghost used on physics process
@export var speed = 4
## Acceleration of chasing ghost used on physics process
@export var accel = 10

@onready var interactionArea = $InteractionFindArea

func _ready():
	nav.set_physics_process(false)
	#called on first frame, loads on next to avoid conflict
	call_deferred("nav_setup")
	randomize() #seed
	spawn_ghost(0) #TODO update difficulty

func _process(_delta):
	#if player_inside: #TODO temporary. Goto _process_physics for real
		#look_at(player.position)
	if player_inside and Input.is_action_just_pressed("interact") and !is_searching:
		# BUG sometimes the ghost doesn't disappear after interacting
		print("Ghost found")
		interactionArea.monitoring = false
		ghost_found.emit()
		spawn_ghost(0) #TODO update difficulty

# load after first frame (map syncronization loading on runtime)
#https://github.com/godotengine/godot/issues/84677
func nav_setup():
	await get_tree().physics_frame
	nav.set_physics_process(true)
	nav.target_position = player.global_position
	ready_nav = true
	#Connect the signal of target reached to the ghost
	nav.connect("target_reached", Callable(self, "_on_target_reached"))

# Calculate ghost's navigation
func _physics_process(delta):
	var direction = Vector3()
	#if ready_nav:
		#nav.target_position = player.global_position
	if is_searching:
		direction = nav.get_next_path_position() - global_position
		direction = direction.normalized()
		velocity = velocity.lerp(direction * speed, accel * delta)
		if !nav.is_target_reached():
			move_and_slide()
		look_at(nav.target_position)
	else:
		look_at_player(direction)

# Moves the ghost to a random spawn
# args: difficulty from 0 to spawn_location's number of sub-arrays
func spawn_ghost(difficulty: int):
	if difficulty < 0 or difficulty >= spawn_locations.size():
		print("spawn_ghost: Invalid difficulty level -> %d" %difficulty)
		return
	var positions = spawn_locations[difficulty]
	var rand_index = randi() % positions.size()
	var rand_position: Vector3 = positions[rand_index]
	position = rand_position
	interactionArea.monitoring = true
	print("Spawned ghost @%s diff %d" % [rand_position, difficulty])

# Ghost looks at player when he's near (broken)
func look_at_player(direction: Vector3) -> void:
	#TODO Rotate the ghost if player is near
	if position.distance_to(player.position) <= close_distance:
		direction = player.position.normalized()
		direction.y = 0
		#rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 10.0)
		#BUG fix this shit

# Trigger box of ghost area3D node with collided body (player)
func _on_3d_body_entered(coll_body):
	if coll_body is Player:
		player_inside = true

func _on_3d_body_exited(coll_body):
	if coll_body is Player:
		player_inside = false

#Signal from end of main timer of player searching
#Also where navigation gets target
func _on_main_timer_timeout():
	is_searching = !is_searching
	on_searching_change.emit(is_searching)
	if is_searching: #is searching this new timer
		#Gets out from hiding spot
		get_node("SlideAppear").play()
		await ghost_appear_slide(-1)
		#Move the ghost to a starting seeking position randomly
		var rnd = randi_range(0, starting_seek_position.size()-1)
		position = starting_seek_position[rnd]
		position.y -= 5
		get_node("SlideAppear").play()
		await ghost_appear_slide(1)
		nav_region.enabled = true
		print("Ghost: spawned searching ghost @%s" % position)
		
		#Nav search. First movement direction, nav will keep going on _on_target_reached
		if !ready_nav:
			printerr("Ghost: navigation not ready when defining target")
		nav.target_position = director.get_random_node_pos()
		
	else: #is hiding this new timer
		#Stops searching
		nav_region.enabled = false
		get_node("SlideAppear").play()
		await ghost_appear_slide(-1)
		spawn_ghost(0) #TODO update difficulty

func ghost_appear_slide(direction: int) -> void:
	#NOTE may be bugged. skip if not searching
	#to avoid unexpected movement in hiding
	#it's not this. Can remove if needed
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

#Nav aux functions

#Signal from nav agent when reached search node.
#Handles the ghost's behavior on how to proceed
func _on_target_reached():
	print("Ghost: reached target position")
	###TODO finish the behaviour

#Nav SearchNode reached option.
#TODO Will look around to search for the player
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

func _on_game_manager_debug():
	nav.debug_enabled = not nav.debug_enabled
