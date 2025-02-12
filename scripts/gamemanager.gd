extends Node
class_name GameManager

#Check to show debug tools in the game, fps counter, game version...
var debug_mode: bool = false

#sends the current state of debug to other scripts
signal debug(status: bool)

@onready var player = $"../Player"
@export var nav_region: NavigationRegion3D

#main timer of the game
var timer: Timer
var aux_timer
@export var timerLabel: Label
# sound hint of the last 5 seconds
var countdownSound
# bool lock for the countdown sound hint, because of _process()
var countdownsfx_lock: bool = false
signal set_countdownsfx

@export var timer_time: int = 90

# FRAMEWORK/DEBUG/GAME CONFIG

var ghostdirector_debug_text: String = "ghostDirector not updated"

#Writes to screen the debug game version.
#TODO Remove before final build
func printGameVersion():
	var game_version = ProjectSettings.get_setting("application/config/version")
	var resolution = DisplayServer.window_get_size() + Vector2i(2,2)
	var fov = player.get_node("Pivot/Camera3D").fov
	
	$"../UserInteface/DEBUG/Version".text = \
	"hdnsk version %s\nresolution:%s FOV:%s\n \
	%sfps (time: %0.2fms)\nmemory: %0.2fmb (out of %0.2fmb)\n \
	vram: %0.1fmb (%d calls), %d objects\n \
	%s" \
	% [game_version, resolution, fov, \
	Performance.get_monitor(Performance.TIME_FPS), \
	Performance.get_monitor(Performance.TIME_PROCESS)*1000,\
	Performance.get_monitor(Performance.MEMORY_STATIC)/1000000, \
	Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/1000000, \
	Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1000000, \
	Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), \
	Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), \
	ghostdirector_debug_text]

func set_director_debug_text(active_search: bool, nodes: int = 0) -> void:
	ghostdirector_debug_text = "active_search %s \n \
	Active search_nodes: %d" % [active_search, nodes]

func _ready():
	if !timerLabel:
		printerr("GameManager: timerLabel not defined in the inspector")
	
	timer = get_node("MainTimer")
	aux_timer = get_node("AuxTimer")
	timerLabel.visible = false
	
	countdownSound = get_node("CountdownSound")

func _process(_delta):
	if debug_mode:
		$"../UserInteface/DEBUG/FPS".text = str(Performance.get_monitor(Performance.TIME_FPS)) + " FPS"
		printGameVersion()
	
	var time:int = int(timer.get_time_left())
	if time > 60:
		#BUG integer,float division error?
		timerLabel.text = "Time left: %02d:%02d" % [int(floor(time/60)), int(time % 60)]
	else:
		timerLabel.text = "Time left: %0.0fs" % time
		
	#Countdown close to the end starts audio hint
	if timer.time_left <= 15 and timer.time_left > 0 and !countdownsfx_lock:
		print("GameManager: Countdown audio")
		countdownsfx_lock = true
		set_countdownsfx.emit()

#Receives signal from countdownsfx telling it's done and unlocks
func _on_countdown_sound_finished_sfx():
	countdownsfx_lock = false

func _input(event):
	# Handler to switch window mode WINDOW/FULLSCREEN w/ F11 ALT+ENTER
	if event.is_action_pressed("set_fullscreen"):
		print("GameManager: set fullscreen")
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event.is_action_pressed("set_debug_mode"):
		var debug_group = $"../UserInteface/DEBUG"
		debug_mode = not debug_mode
		debug_group.visible = not debug_group.visible
		#debug.emit()
		emit_signal("debug", debug_mode)
	if event.is_action_pressed("pause_timer"):
		if !timer.is_stopped():
			timer.stop()
		else:
			timer.start()

# GAMEPLAY

#timer
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

#NOTE add recently added addons on obsidian


