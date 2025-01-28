extends Node3D
class_name Event

## Signal to notify when animation is done
signal animation_finished()

func _ready():
	visible = false

func play_animation() -> void:
	visible = true
	$AnimationPlayer.play("flying_test")

func _on_animation_player_animation_finished(_anim_name):
	visible = false
	animation_finished.emit()
