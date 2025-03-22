extends SpotLight3D

@export var button_sfx: AudioStreamPlayer3D

@export var flicker_min_wait: float = 10
@export var flicker_max_wait: float = 60

var flicker_timer: Timer

func _ready() -> void:
	flicker_timer = Timer.new()
	flicker_timer.wait_time = randf_range(flicker_min_wait, flicker_max_wait)
	flicker_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(flicker_timer)
	flicker_timer.owner = self

func toggle_flashlight() -> void:
	visible = !visible
	if button_sfx:
		button_sfx.play()
	if visible:
		flicker_timer.start()
	else:
		flicker_timer.stop()

func _on_timer_timeout() -> void:
	flicker_effect()
	flicker_timer.wait_time = randf_range(flicker_min_wait, flicker_max_wait)
	flicker_timer.start()

func flicker_effect() -> void:
	for n in 8:
		visible = !visible
		await get_tree().create_timer(randf_range(0.01,0.1)).timeout
