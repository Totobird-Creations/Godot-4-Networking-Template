shader_type spatial;
render_mode shadows_disabled, unshaded;

uniform sampler2D star_noise_0;
uniform sampler2D star_noise_1;
uniform sampler2D star_noise_2;
uniform float     star_count   : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float count  = sqrt(star_count);
	float star_0 = pow(texture(star_noise_0, UV.xy + NODE_POSITION_WORLD.xz / 500.0).r,  7.5) > 0.5 - (0.475 * count) ? 0.5 : 0.0;
	float star_1 = pow(texture(star_noise_1, UV.xy + NODE_POSITION_WORLD.xz / 750.0).r,  7.5) > 0.5 - (0.475 * count) ? 0.25  : 0.0;
	float star_2 = pow(texture(star_noise_2, UV.xy + NODE_POSITION_WORLD.xz / 1000.0).r, 7.5) > 0.5 - (0.475 * count) ? 0.125 : 0.0;
	ALBEDO = vec3(max(star_0, max(star_1, star_2)));
}
