shader_type spatial;
render_mode unshaded;

// Ripple effect uniforms
uniform float frequency: hint_range(0, 15, 0.01) = 4.0;
uniform float amplitude: hint_range(0, 5, 0.1) = 3.0;
uniform float ripple_rate: hint_range(0, 20.0, 1) = 5.0;

// Fading distance control
uniform float fade_start: hint_range(0, 50, 1) = 10.0;
uniform float fade_end: hint_range(0, 100, 1) = 30.0;

// Camera position (passed from script)
uniform vec3 camera_position;

varying vec3 frag_world_position;

void vertex() {
    frag_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Calculate distance from the camera to the world position
    float camera_distance = length(frag_world_position - camera_position);

    // Calculate fade factor based on camera distance
    float fade_factor = clamp(1.0 - smoothstep(fade_start, fade_end, camera_distance), 0.0, 1.0);

    // Debug visualization
    ALBEDO = vec3(camera_distance / fade_end); // Optional: Visualize normalized camera distance
    ALPHA = fade_factor; // Apply fade effect
}
