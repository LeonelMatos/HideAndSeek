extends SpotLight3D

@export var button_sfx: AudioStreamPlayer3D

@export var flicker_min_wait: float = 10
@export var flicker_max_wait: float = 120

var flicker_timer: Timer

var button_fail: bool = false

##Chance in percentage if the flashlight will fail when turning on.
@export var button_fail_chance: float = 0.1:
	set(value): button_fail_chance = maxf(0, value)

var retry_attempts: int = 0

func _ready() -> void:
	visible = false
	flicker_timer = Timer.new()
	flicker_timer.wait_time = randf_range(flicker_min_wait, flicker_max_wait)
	flicker_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(flicker_timer)
	flicker_timer.owner = self

func toggle_flashlight(silent:bool = false) -> void:
	if button_sfx and !silent:
		button_sfx.play()
	if button_fail:
		retry_attempts -= 1
		if retry_attempts == 0:
			button_fail = false
		return
	visible = !visible
	if visible:
		flicker_timer.start()
	else:
		flicker_timer.stop()
		if randf() <= button_fail_chance:
			button_fail = true
			retry_attempts = randi_range(2,6)

func _on_timer_timeout() -> void:
	flicker_effect()
	#Chance of turning flashlight off
	if randf() <= 0.5:
		toggle_flashlight(true)
	flicker_timer.wait_time = randf_range(flicker_min_wait, flicker_max_wait)
	flicker_timer.start()

func flicker_effect() -> void:
	for n in 8:
		visible = !visible
		await get_tree().create_timer(randf_range(0.01,0.1)).timeout
