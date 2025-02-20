shader_type canvas_item;

uniform vec4 water_tint : source_color = vec4(1,0,1,1);
uniform vec2 sprite_scale = vec2(1,1);
uniform vec2 parent_position = vec2(1,1);
uniform float scale_x = 0.65;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest_mipmap;

uniform float surface_width = 0.2;
uniform vec4 surface_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 water_size = vec2(720.0, 1080.0);

uniform vec2 scroll1 = vec2(0.2, 0.02);
uniform vec2 scroll2 = vec2(-0.2, -0.02);

float rand(vec2 coord){
	return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 coord){
	vec2 i = floor(coord);
	vec2 f = fract(coord);

	// 4 corners of a rectangle surrounding our point
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 cubic = f * f * (3.0 - 2.0 * f);

	return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

void fragment(){
	vec2 noisecoord1 = UV * sprite_scale * scale_x;
	vec2 noisecoord2 = UV * sprite_scale * scale_x + 4.0;

	vec2 motion1 = vec2(TIME * 0.3, TIME * -0.4);
	vec2 motion2 = vec2(TIME * 0.1, TIME * 0.5);

	vec2 distort1 = vec2(noise(noisecoord1 + motion1), noise(noisecoord2 + motion1)) - vec2(0.5);
	vec2 distort2 = vec2(noise(noisecoord1 + motion2), noise(noisecoord2 + motion2)) - vec2(0.5);

	vec2 distort_sum = (distort1 + distort2) / 60.0;

	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV + distort_sum, 0.0);

	color = mix(color, water_tint, 0.4);
	color.rgb = mix(vec3(0.5), color.rgb, 1.4);

	float water_top = (parent_position.y - water_size.y) / (1.0/SCREEN_PIXEL_SIZE).y;
	
    // Calculate the top gradient based on the Y-coordinate
	float gradient = smoothstep(water_top, water_top + surface_width, SCREEN_UV.y);
	
	//Mix top surface color
	vec4 color2 = mix(surface_color, color, gradient);
	
	//Mix water texture
	COLOR = mix(color2, texture(TEXTURE, UV - scroll1 * TIME), 0.05);

}