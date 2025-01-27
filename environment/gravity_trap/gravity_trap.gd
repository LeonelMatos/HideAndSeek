extends Node3D
class_name Trap

@onready var trap_center: Vector3 = global_transform.origin
@onready var mesh: MeshInstance3D = $GravityMesh
@onready var audio_player: AudioStreamPlayer3D = $ProximitySFX

#TODO Refactoring
@export_group("Gravity Force")
##Strenght of the field's pull
@export var pull_force: float = 3.0
##Distance of gravity's pull
@export var pull_radius: float = 8.0
##Maximum speed the body affected will go.
##BUG Doesn't increase the area3D range
@export var max_pull_speed: float = 30.0

##Specific for Player. Distance to act effects on player
##Must be less than pull_radious
@export var proximity_threshold: float = 7.0:
	set(value):
		proximity_threshold = min(value, pull_radius)

var affected_bodies: Array[PhysicsBody3D] = []
# To track if the player is already within range
var player_within_proximity = false

## Signal to notify when the player is near a trap by distance.
##Passes the state enable and the distance
signal trap_caught_player(enable: bool, distance: float)

func _ready() -> void:
	pass

func _physics_process(delta):
	for body in affected_bodies:
		var body_pos: Vector3 = body.global_transform.origin
		
		if !is_instance_valid(body):
			continue
			
		# Calculate the direction to center
		var direction: Vector3 = (trap_center - body_pos).normalized()
		# Apply force toward the center
		var distance: float = trap_center.distance_to(body_pos)
		if distance <= pull_radius:
			var force_magnitude = pull_force * (1.0 - (distance / pull_radius))  # Stronger pull closer to the center
			var velocity = direction * pull_force
			if velocity.length() > max_pull_speed:
				velocity = velocity.normalized() * max_pull_speed
			body.move_and_collide(velocity * delta)
			if body is CharacterBody3D and body.name == "Player":
				player_effect(body, distance)

func player_effect(player: CharacterBody3D, distance: float) -> void:
	pitch_by_distance(distance)
	volume_by_distance(distance)
	
	if distance <= proximity_threshold:
		vignette_effect(true, distance)
	else:
		vignette_effect(false, distance)
	
	if distance <= proximity_threshold and !player_within_proximity:
		player_within_proximity = true
		#Disable running
		if !audio_player.playing:
			audio_player.play()
	elif distance > proximity_threshold and player_within_proximity:
		player_within_proximity = false
		audio_player.stop()
		reset_audio()

func _on_area_3d_body_entered(body):
	if body is RigidBody3D or body is CharacterBody3D:
		affected_bodies.append(body)

func _on_area_3d_body_exited(body):
	if body in affected_bodies:
		affected_bodies.erase(body)
		if body.name == "Player":
			player_within_proximity = false
			emit_signal("trap_caught_player", false)
			reset_audio()

func _on_proximity_sfx_finished():
	audio_player.play()

func pitch_by_distance(distance: float) -> void:
	var x = maxf(distance, 1.8)
	var pitch = 1/log(x)
	audio_player.pitch_scale = pitch

#TODO check if actually works with negative values as intended
func volume_by_distance(distance: float) -> void:
	var x = maxf(distance, 1.5)
	var volume = -10*log(x)+8
	audio_player.volume_db = volume

func reset_audio() -> void:
	audio_player.stop()
	audio_player.pitch_scale = 1
	audio_player.volume_db = 0

func vignette_effect(status: bool, distance: float) -> void:
	emit_signal("trap_caught_player", status, distance)
