shader_type canvas_item;
// Wind sway for props: shears the sprite about its anchored edge. Rooted things
// (trees, grass) keep their base still; hanging things (webs, chains) keep their top.
// Phase comes from world position so neighbours never move in step.

uniform float amount = 2.0;        // pixels of travel at the free edge
uniform float speed = 1.4;
uniform bool hanging = false;

void vertex() {
	float free = hanging ? UV.y : 1.0 - UV.y;
	float phase = MODEL_MATRIX[3].x * 0.05 + MODEL_MATRIX[3].y * 0.031;
	float wave = sin(TIME * speed + phase) + 0.35 * sin(TIME * speed * 2.7 + phase * 1.7);
	VERTEX.x += free * amount * wave;
}
