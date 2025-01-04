extends AudioStreamPlayer3D

@export var player: Player

## Distance range x away from player
@export var random_range_x: int = 10
## Distance range z away from player
@export var random_range_z: int = 10
## Height above player
@export var height: int = 20

signal finished_sfx

func _ready():
	if !player:
		printerr("Countdownsfx: player not assigned")
	randomize()

func _on_manager_set_countdownsfx():
	var offset_x = randi_range(-random_range_x, random_range_x)
	var offset_z = randi_range(-random_range_z, random_range_z)
	global_transform.origin = player.position + Vector3(offset_x, height, offset_z)
	#print("CountdownSfx: spawned @(%s) with offset %sx %sz" % [global_transform.origin, offset_x, offset_z])
	play()
	wait()

# Waits for the audio to finish playing and send a signal telling it ended
func wait() -> void:
	await get_tree().create_timer(stream.get_length()).timeout
	finished_sfx.emit()
