package game

import rl "vendor:raylib"

MAX_INPUTTER_HITBOX_COUNT :: 1024


Inputter ::  /* heavy */struct {
	target:              ^Hitbox,
	hovered:             bool,
	down:                bool,

	// internal
	_hitbox_stack_index: u16,
	_hitbox_stack:       [MAX_INPUTTER_HITBOX_COUNT]^Hitbox,
}

inputter_create :: proc() -> ^Inputter {
	inputter := new(Inputter)

	inputter.target = nil
	inputter.hovered = false
	inputter.down = false
	inputter._hitbox_stack = {}

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


inputter_clear :: proc(i: ^Inputter) {
	i._hitbox_stack = {}
	i._hitbox_stack_index = 0
}

inputter_advance_hitbox :: proc(i: ^Inputter, h: ^Hitbox) {
	if i == nil || h == nil do return

	i._hitbox_stack[i._hitbox_stack_index] = h
	i._hitbox_stack_index += 1
}
