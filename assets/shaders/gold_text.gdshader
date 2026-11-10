shader_type canvas_item;
// Banded relic gold for title letters, with a glint that sweeps across now and then.
// `heat` > 0 makes the letters white-hot (the forging intro), cooling to gold at 0.

uniform float text_top = 0.0;
uniform float text_height = 32.0;
uniform float heat : hint_range(0.0, 1.0) = 0.0;
uniform float glint_period = 4.0;

varying vec2 local_pos;

const vec3 BANDS[6] = vec3[6](
	vec3(1.0, 0.984, 0.902), vec3(1.0, 0.914, 0.659), vec3(1.0, 0.839, 0.42),
	vec3(0.961, 0.722, 0.263), vec3(0.851, 0.545, 0.141), vec3(0.659, 0.38, 0.102));

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float a = texture(TEXTURE, UV).a * COLOR.a;
	float k = clamp((local_pos.y - text_top) / text_height, 0.0, 0.999);
	vec3 gold = BANDS[int(k * 6.0)];
	float sweep = fract(TIME / glint_period) * 3.0 - 1.0;
	float glint = step(abs(local_pos.x / 300.0 - sweep + k * 0.15), 0.02);
	vec3 col = mix(gold, vec3(1.0), glint * 0.8);
	col = mix(col, vec3(1.0, 0.97, 0.9), heat);
	COLOR = vec4(col, a);
}
