package game

import rl "vendor:raylib"


Hitbox ::  /* heavy */struct {
	active: bool,
	rect:   [4]f32,
	color:  rl.Color,
}

obj_hitbox_create :: proc(rect: [4]f32, color := rl.RED) -> ^Hitbox {
	hitbox := new(Hitbox)

	hitbox.active = true
	hitbox.rect = rect
	hitbox.color = color

	return hitbox
}

obj_hitbox_destroy :: proc(h: ^Hitbox) {
	// ...

	free(h)
}


obj_hitbox_advance :: proc(h: ^Hitbox) {
	inputter_advance_hitbox(inputter_get_singleton(), h)
}

obj_hitbox_queue_debug_draw :: proc(h: ^Hitbox, c: Maybe(rl.Camera2D) = nil) {
	game_queue_debug_draw(Game_DebugDraw_Op_Rect{rect = h.rect, color = h.color, camera = c})
}
