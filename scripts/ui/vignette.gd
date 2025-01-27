extends ColorRect

##Maximum distance from the trap
@export var max_distance: float = 8.0  
##Minimum alpha value
@export var min_alpha: float = 0.1
##Maximum alpha value
@export var max_alpha: float = 0.8

var is_enable_applied: bool = false

var shader_material: ShaderMaterial

func _ready() -> void:
	shader_material = material as ShaderMaterial
	connect_to_traps()

#BUG Not working, not connecting
func connect_to_traps() -> void:
	var traps = get_tree().get_nodes_in_group("Trap")
	for trap in traps:
		trap.connect("trap_caught_player", Callable(self, "enable_vignette"))

func enable_vignette(enable: bool, distance: float = 0.0) -> void:
	vignette_by_distance(enable, distance)
	if enable and !is_enable_applied:
		visible = enable
		is_enable_applied = true
		print("Vignette: enabled")
	elif !enable and is_enable_applied:
		visible = enable
		is_enable_applied = false
		print("Vignette: disabled")

# Adjust vignette alpha based on distance
func vignette_by_distance(enable: bool, distance: float) -> void:
	if enable:
		# Calculate alpha dynamically based on distance
		var normalized_distance = clamp(distance / max_distance, 0.0, 1.0)
		var intensity_factor = pow(normalized_distance, 3)
		var alpha = lerp(max_alpha, min_alpha, intensity_factor)
		shader_material.set_shader_parameter("MainAlpha", alpha)
		print("Vignette alpha set to: ", alpha)
