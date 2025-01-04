extends AudioStreamPlayer

@onready var wind = $"."

#for transitioning between trigger boxes
#waits for a moment before deciding to change the audio
var trigger_overlap: bool = false

##For transitioning between trigger boxes.
##Waits for a moment before deciding to change the audio
@export var transition_time := 0.7


func _on_finished():
	play()

func _ready():
	for child in get_children():
		if child is Node3D:
			child.sound_env_enter.connect(on_sound_env_enter)
			child.sound_env_exit.connect(on_sound_env_exit)

func on_sound_env_enter():
	trigger_overlap = true
	await sound_crossfade_int()

func on_sound_env_exit():
	if !trigger_overlap:
		await sound_crossfade_ext()

func sound_crossfade_int():
	await get_tree().create_timer(0.7).timeout
	trigger_overlap = false
	if volume_db > -10: #-10 is a buffer zone
		for n in 20:
			volume_db -= 0.25
			pitch_scale -= 0.02
			await get_tree().create_timer(0.05).timeout
		volume_db = -5
		pitch_scale = 0.7

func sound_crossfade_ext():
	for n in 20:
		volume_db += 0.25
		pitch_scale += 0.02
		await get_tree().create_timer(0.05).timeout
	volume_db = 0
	pitch_scale = 1
