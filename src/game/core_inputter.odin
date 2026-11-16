package game

import "core:crypto/aead"
import "core:log"
import "utils"

import rl "vendor:raylib"

MAX_INPUTTER_HITBOX_CAP :: 1024


HitboxCameraPair :: struct {
	hitbox: ^Hitbox,
	camera: rl.Camera2D,
}

Inputter ::  /* heavy */struct {
	target:                  ^Hitbox,
	down:                    [rl.MouseButton]bool,
	pressed:                 [rl.MouseButton]bool,

	// internal
	_prev_target:            ^Hitbox,
	_hitbox_stack_len:       u16,
	_hitbox_stack:           [MAX_INPUTTER_HITBOX_CAP]^Hitbox,
	_hitbox_world_stack_len: u16,
	_hitbox_world_stack:     [MAX_INPUTTER_HITBOX_CAP]HitboxCameraPair,
}

inputter_create :: proc() -> ^Inputter {
	inputter := new(Inputter)

	inputter.target = nil
	inputter.down = {}

	inputter._hitbox_stack = {}
	inputter._hitbox_world_stack = {}

	return inputter
}

inputter_destroy :: proc(i: ^Inputter) {
	// ...

	free(i)
}

inputter_get_singleton :: proc() -> ^Inputter {
	game := game_get_singleton()
	if game == nil do return nil

	return game.inputter
}


inputter_dispatch :: proc(i: ^Inputter) {
	inputter_clear(i)
}

inputter_post_process :: proc(i: ^Inputter) {
	i._prev_target = i.target
	i.target = nil

	// world 2d pass
	for idx in 0 ..< i._hitbox_world_stack_len {
		pair := i._hitbox_world_stack[idx]
		world_mouse := rl.GetScreenToWorld2D(utils.highdpi_mouse_pos(), pair.camera)

		if rl.CheckCollisionPointRec(world_mouse, transmute(rl.Rectangle)pair.hitbox.rect) {
			i.target = pair.hitbox
		}
	}

	// ui pass
	for idx in 0 ..< i._hitbox_stack_len {
		hitbox := i._hitbox_stack[idx]
		mouse := rl.GetMousePosition()

		if rl.CheckCollisionPointRec(mouse, transmute(rl.Rectangle)hitbox.rect) {
			i.target = hitbox
		}
	}

	// everything else after we determined final hitbox
	if i.target == nil {
		for v in rl.MouseButton {
			i.down[v] = false
			i.pressed[v] = false
		}
	} else {
		for v in rl.MouseButton {
			i.down[v] = rl.IsMouseButtonDown(v)
			i.pressed[v] = i._prev_target == i.target && rl.IsMouseButtonPressed(v)
		}
	}
}


inputter_clear :: proc(i: ^Inputter) {
	i._hitbox_stack_len = 0
	i._hitbox_world_stack_len = 0
}

inputter_advance_hitbox :: proc(i: ^Inputter, h: ^Hitbox, c: Maybe(rl.Camera2D) = nil) {
	if i == nil || h == nil do return

	if camera, ok := c.?; ok {
		i._hitbox_world_stack[i._hitbox_world_stack_len] = {h, camera}
		i._hitbox_world_stack_len += 1
	} else {
		i._hitbox_stack[i._hitbox_stack_len] = h
		i._hitbox_stack_len += 1
	}
}
