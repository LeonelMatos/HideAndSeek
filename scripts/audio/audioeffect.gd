extends AudioStreamPlayer3D
#Doppler effect activated using tracking to idle, might help

var debug_mode: bool = false

@export var player : Node3D

func _on_ghost_found():
	var player_pos = player.global_transform.origin
	var player_forward = $"../Player/Pivot".global_transform.basis.z.normalized()
	var spawn_distance = 10
	var spawn_pos = player_pos + player_forward * spawn_distance + Vector3(0,40,0)
	
	position = spawn_pos
	
	if debug_mode:
		print("audioeffect: spawned debug audio at %s", spawn_pos)
	play()

func _on_game_manager_debug():
	debug_mode = not debug_mode
