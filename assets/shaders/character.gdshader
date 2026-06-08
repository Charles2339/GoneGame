shader_type canvas_item;
render_mode blend_mix;

uniform float time_scale: hint_range(0.0, 2.0) = 1.0;
uniform float intensity: hint_range(0.0, 1.0) = 0.5;
uniform bool enable_outline = true;
uniform vec3 outline_color: hint_color = vec3(1.0);

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	
	// Outline effect
	if (enable_outline) {
		float sample_dist = 2.0 / float(textureSize(TEXTURE, 0).x);
		vec4 outline = texture(TEXTURE, UV + vec2(sample_dist, 0.0)) +
					   texture(TEXTURE, UV - vec2(sample_dist, 0.0)) +
					   texture(TEXTURE, UV + vec2(0.0, sample_dist)) +
					   texture(TEXTURE, UV - vec2(0.0, sample_dist));
		
		if (outline.a > original_color.a) {
			COLOR = vec4(outline_color, original_color.a * 0.5);
		} else {
			COLOR = original_color;
		}
	} else {
		COLOR = original_color;
	}
	
	// Glow effect
	COLOR.rgb += texture(TEXTURE, UV).rgb * intensity * 0.2;
}
