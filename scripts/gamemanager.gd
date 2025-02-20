extends Node
class_name GameManager

# Sends the current state of debug to other scripts
signal debug(status: bool)

signal set_countdownsfx

## Group: Debug-----------------------------------------------------------------
@export_group("Debug")
## Enable debug tools in-game.
@export var debug_mode: bool = false:
	set(value):
		debug_mode = value
		debug_group.visible = value
		emit_signal("debug", value)

## Display relevant debug info.
@export var debug_info: Label
##Canvas group of debug info display.
@export var debug_group: CanvasGroup
## Display FPS counter on screen.
@export var fps_display: Label
@export_subgroup("Extra")
## Display FPS color. [i](Default: dark_green)[/i].
@export_color_no_alpha var fps_color: Color = Color.DARK_GREEN

## Group: Timer-------------------------------------------------------------
@export_group("Timer")
## [b]Game time[/b] [i](default: 1m30s)[/i].
@export var timer_time: int = 90
## Enables the navigation when the timer is working.
@export var nav_region: NavigationRegion3D #TODO check if deprecated
## UI label to show the remaining time.
@export var timerLabel: Label
## Effects enabled when near end of time. [br][i](Auxiliar to Timer)[/i].
@export var countdown_time: int = 15:
	set(value): countdown_time = maxi(0, value)

# Main timer of the game
var timer: Timer
# Temporary to allow showing the starting splash screens
var aux_timer: Timer
# sound hint of the last 5 seconds
var countdownSound
# bool lock for the countdown sound hint, because of _process()
var countdownsfx_lock: bool = false

@onready var player: Player = get_tree().get_first_node_in_group("Player") as Player:
	set(value):
		if !value:
			push_error("Missing player node in scene")
		player = value

static var cached_debug_info: Dictionary = {
	"version" : get_game_version()
}

#region Lifecycle Methods
#-------------------------------------------------------------------------------
func _ready():
	if !timerLabel:
		printerr("GameManager: timerLabel not defined in the inspector")
	set_fps_color(fps_color)
	init_timer()

func _process(_delta):
	var time: float = timer.get_time_left()
	if debug_mode:
		fps_display.text = fps_to_string()
		print_debug_info()
	timerLabel.text = timer_to_string(time)
		
	on_countdown(time)
#endregion

#region Debug Config
#-------------------------------------------------------------------------------
var enemy_director_debug: String = "Enemy Director not updated"

#Writes to screen the debug game version.
func print_debug_info():
	debug_info.text = """\
	hdnsk version {version}
	Resolution: {resolution} | FOV: {fov}
	{fps} FPS (Process Time: {process_time}ms)
	Memory: {memory_used} MB / {memory_max} MB
	VRAM: {vram_used} MB | Draw Calls: {draw_calls} | Objects: {obj_rendered}
	{enemy_director_debug}
	""".format({
		"version": cached_debug_info,
		"resolution": get_resolution(),
		"fov": player.get_cam_fov(),
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_time": "%.2f" % [Performance.get_monitor(Performance.TIME_PROCESS)*1000],
		"memory_used": "%.2f" % [Performance.get_monitor(Performance.MEMORY_STATIC)/1_000_000],
		"memory_max": "%.2f" % [Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/1_000_000],
		"vram_used": "%.1f" % [Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1_000_000],
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"obj_rendered": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"enemy_director_debug": enemy_director_debug
	})

func set_director_debug_text(active_search: bool, nodes: int = 0) -> void:
	enemy_director_debug = "active_search %s \n \
	Active search_nodes: %d" % [active_search, nodes]

func fps_to_string() -> String:
	return str(Performance.get_monitor(Performance.TIME_FPS)) + " FPS"

func set_fps_color(color: Color) -> void:
	fps_display.add_theme_color_override("fps_color", color)
#endregion

#region Input
#-------------------------------------------------------------------------------
func _input(event):
	# Handler to switch window mode WINDOW/FULLSCREEN w/ F11 ALT+ENTER
	if event.is_action_pressed("set_fullscreen"):
		switch_fullscreen()
	if event.is_action_pressed("set_debug_mode"):
		debug_mode = not debug_mode
	if event.is_action_pressed("pause_timer"):
		switch_timer()
#endregions

#region Timer
#-------------------------------------------------------------------------------
func init_timer() -> void:
	timer = get_node("MainTimer")
	aux_timer = get_node("AuxTimer")
	timerLabel.visible = false
	countdownSound = get_node("CountdownSound")
	countdownsfx_lock = false

func timer_to_string(time: float) -> String:
	if time > 60:
		return "Time left: %02d:%02d" % [int(floor(time/60)), (int(time) % 60)]
	else:
		return "Time left: %0.0fs" % time

func switch_timer():
	if !timer.is_stopped():
		timer.stop()
	else:
		timer.start()

func on_countdown(time: float):
	if time <= countdown_time and !countdownsfx_lock:
		countdownsfx_lock = true
		set_countdownsfx.emit()

#AuxTimer starts on run to wait after the splashScreen
# and starts the MainTimer when the game actually starts
func _on_aux_timer_timeout():
	timer.wait_time = timer_time
	timer.start()
	timerLabel.visible = true

func _on_main_timer_timeout():
	nav_region.enabled = not nav_region.enabled
	timer.wait_time = timer_time
	timer.start()

#Receives signal from countdownsfx telling it's done and unlocks
func _on_countdown_sound_finished_sfx():
	countdownsfx_lock = false
#endregion

#region Settings
#-------------------------------------------------------------------------------
static func get_game_version() -> String:
	return ProjectSettings.get_setting("application/config/version")

func get_resolution() -> String:
	return str(DisplayServer.window_get_size() + Vector2i(2,2))

func switch_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
#endregion
