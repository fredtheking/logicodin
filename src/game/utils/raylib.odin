package utils

import "core:log"

import rl "vendor:raylib"


window_size :: proc() -> [2]f32 {
	if !rl.IsWindowReady() {
		log.error("raylib not initialized!")
		return {}
	}

	return {f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())}
}

highdpi_mouse_pos :: proc() -> [2]f32 {
	if !rl.IsWindowReady() {
		log.error("raylib not initialized!")
		return {}
	}

	return rl.GetMousePosition() * rl.GetWindowScaleDPI()
}
