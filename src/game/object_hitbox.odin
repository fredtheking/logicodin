package game

import rl "vendor:raylib"


Hitbox ::  /* heavy */struct {
	color: rl.Color,
}

obj_hitbox_create :: proc() -> ^Hitbox {
	hitbox := new(Hitbox)

	hitbox.color = rl.RED

	return hitbox
}

obj_hitbox_destroy :: proc(h: ^Hitbox) {
	// ...

	free(h)
}
