shader_type canvas_item;

uniform vec2      resolution                    = vec2(0);
uniform int       rarity     : hint_range(0, 4) = 0;
uniform sampler2D noise;

void fragment() {
	vec2  pos    = UV * resolution;
	float alpha  = texture(TEXTURE, UV).a;
	vec3  colour = (
		   rarity == 1
		? vec3(1.0, 1.0, 0.0)
		: (rarity == 2
		? vec3(0.0, 0.75, 1.0)
		: (rarity == 3
		? vec3(1.0, 0.0, 1.0)
		: (rarity == 4
		? vec3(01.0, 0.0, 0.0)
		: vec3(1.0, 1.0, 1.0)
		)))
	);
	if (rarity >= 2) {
		vec2  shine_pos   = pos / 100.0;
		float shine_size  = 0.05;
		float shine_speed = 3.0;
		colour += vec3(step(1.0 - shine_size * 0.5, 0.5 + 0.5 * sin(shine_pos.y - shine_pos.x + TIME * shine_speed))) * 0.75;
	}
	if (rarity >= 4) {
		vec2 ratio = (TEXTURE_PIXEL_SIZE.x > TEXTURE_PIXEL_SIZE.y) ? vec2(TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x, 1.0) : vec2(1.0, TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y);
		vec2 uv    = (((UV - 0.5) * ratio + 0.5) * 1.5) + vec2(0.0, TIME * 0.5);
		vec3 alt   = vec3(1.0, 1.0, 0.0);
		colour = vec3(texture(noise, mod(uv, vec2(1.0))).r <= UV.y
			? alt + (colour - alt) * UV.y
			: colour + (alt - colour) * UV.y
		);
	}
	colour = clamp(colour, vec3(0.0), vec3(1.0));
	COLOR  = vec4(colour, alpha);
}
