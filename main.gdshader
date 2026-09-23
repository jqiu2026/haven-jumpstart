shader_type canvas_item;

uniform vec2 player_screen_pos = vec2(0.5, 0.5); // Center of the screen (0.0 to 1.0)
uniform float circle_radius : hint_range(0.0, 1.0) = 0.1; // Size of the clear circle
uniform float feather : hint_range(0.0, 1.0) = 0.1; // Softness of the circle's edge
uniform vec4 blind_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Opaque black overlay

void fragment() {
    // Adjust for screen aspect ratio so the circle doesn't look stretched like an oval
    vec2 aspect_ratio = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
    vec2 uv_adjusted = UV * aspect_ratio;
    vec2 pos_adjusted = player_screen_pos * aspect_ratio;
    
    // Calculate distance from the current pixel to the player center
    float dist = distance(uv_adjusted, pos_adjusted);
    
    // Smoothly blend from transparent (0.0) inside the circle to blind_color (1.0) outside
    float alpha = smoothstep(circle_radius, circle_radius + feather, dist);
    
    // Mix the color based on the distance
    COLOR = mix(vec4(0.0), blind_color, alpha);
}
