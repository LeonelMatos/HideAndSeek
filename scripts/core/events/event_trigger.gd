extends Area3D
class_name EventTrigger

@export_group("Event")
##[b]Animation event[/b] to play when trigger activates.
@export var event: Event
##Probability of event to happen.
@export_range(0,1) var chance: float
##Only plays the event [b]once[/b].
@export var play_once: bool = false
@export_group("Player Facing")
##Animation only plays if player is looking in that direction.
@export var player_facing: bool = false
##Determines how strictly the player needs to be facing the event.
##[br][i](closer to 1 means stricter)[/i]
@export_range(0,1) var facing_threshold = 0.3
##Controls whether height should be ignored when [code]true[/code].
@export var ignore_height: bool = true

var lock: bool = false

@onready var debug_mesh: MeshInstance3D = $DebugMesh
@onready var debug_name: Label3D = $EventName
var player: Player

func _ready():
	assert(event != null, "Event must be assigned to the trigger")
	var game_manager = get_tree().get_first_node_in_group("GameManager")
	event.connect("animation_finished", Callable(self, "on_animation_finished"))
	game_manager.connect("debug", Callable(self, "_on_game_manager_debug"))
	debug_mesh.visible = false
	debug_name.visible = false
	debug_name.text = event.name
	player = get_tree().get_first_node_in_group("Player")

func _on_body_entered(body):
	if body.name == "Player" and !lock:
		if player_facing and !is_player_facing(event.global_transform.origin):
			return
		if randf() <= chance:
			lock = true
			event.play_animation()

func on_animation_finished() -> void:
	if !play_once:
		lock = false

func is_player_facing(event_position: Vector3) -> bool:
	var player_forward: Vector3 = -player.global_transform.basis.z.normalized()
	var to_event: Vector3 = (event_position - player.global_transform.origin).normalized()
	# If ignoring height, set the Y component of both vectors to 0
	if ignore_height:
		player_forward.y = 0
		player_forward = player_forward.normalized()  # Re-normalize after modification
		to_event.y = 0
		to_event = to_event.normalized()  # Re-normalize after modification
	var dot_product: float = player_forward.dot(to_event)
	print("Player Position: ", player.global_transform.origin)
	print("Event Position: ", event_position)
	print("Player Forward: ", player_forward)
	print("To Event: ", to_event)
	print("Dot Product: ", dot_product)
	print("Facing Threshold: ", facing_threshold)
	return dot_product > facing_threshold

func _on_game_manager_debug(status: bool) -> void:
	debug_mesh.visible = status
	debug_name.visible = status
