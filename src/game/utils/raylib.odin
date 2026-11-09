package utils

import "core:log"

import rl "vendor:raylib"


window_size :: proc(ignore_highdpi := false) -> [2]f32 {
	if !rl.IsWindowReady() {
		log.error("raylib not initialized!")
		return {}
	}

	size := [2]f32{f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())}
	if ignore_highdpi {
		size /= rl.GetWindowScaleDPI()
	}

	return size
}

highdpi_mouse_pos :: proc() -> [2]f32 {
	if !rl.IsWindowReady() {
		log.error("raylib not initialized!")
		return {}
	}

	return rl.GetMousePosition() * rl.GetWindowScaleDPI()
}
