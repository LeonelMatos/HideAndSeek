extends Node3D

signal sound_env_enter
signal sound_env_exit

func _ready():
	$Area3D/MeshInstance3D.visible = false

func _on_area_3d_body_entered(body):
	if body is Player:
		#sound_env_enter.emit()
		emit_signal("sound_env_enter")

func _on_area_3d_body_exited(body):
	if body is Player:
		#sound_env_exit.emit()
		emit_signal("sound_env_exit")
