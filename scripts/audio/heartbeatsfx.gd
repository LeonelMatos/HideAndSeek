# Audio SFX when the ghost is chasing the player and is close.
# TODO Need to create a signal or something to impede the audio playing in
#case I need to have a surprise element

extends Area3D

var heartbeat: AudioStreamPlayer

#Indicates when it's the ghost's turn to seek
#If GHOST is searching
#Starts at false for player's turn
var is_searching: bool = false

#If the player is close to the ghost/ inside the area3d to play
#the intense heartbeat

func _ready():
	heartbeat = get_node("HeartBeatSFX")

#Starts the audio when entering area3d
func _on_body_entered(body):
	if body is Player and is_searching:
		heartbeat.volume_db = 0
		heartbeat.play()

func _on_body_exited(body):
	if body is Player and is_searching:
		await lower_sfx_vol()
		heartbeat.playing = false

#Loops the audio until _on_body_exited stops
func _on_heart_beat_sfx_finished():
	heartbeat.play()

#Gradually decreases volume
func lower_sfx_vol():
	for n in 20:
		heartbeat.volume_db -= 1
		await get_tree().create_timer(0.1).timeout

func _on_ghost_on_searching_change(value):
	is_searching = value
	#safekeep to avoid playing when ghost disappears
	if value == false:
		heartbeat.playing = false
