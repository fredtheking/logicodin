package game

import "core:fmt"
import "core:strings"

import "utils"

import rl "vendor:raylib"


SceneOverlay :: struct {
	using scene: Scene,
}

scene_overlay_create :: proc() -> ^Scene {
	scene := new(SceneOverlay)

	scene.tid = SceneOverlay
	scene.on_dispatch = scene_overlay_dispatch
	scene.on_destroy = scene_overlay_destroy
	scene.on_process = scene_overlay_process
	scene.on_draw = scene_overlay_draw

	return scene
}

scene_overlay_dispatch :: proc(s: ^Scene) {
	scene := cast(^SceneOverlay)s

	// ...
}

scene_overlay_destroy :: proc(s: ^Scene) {
	scene := cast(^SceneOverlay)s

	// ...

	free(scene)
}

scene_overlay_process :: proc(s: ^Scene) {
	scene := cast(^SceneOverlay)s

	if rl.IsKeyPressed(.ESCAPE) {
		game_close()
	}
	if rl.IsKeyPressed(.GRAVE) {
		game_switch_debug()
	}
}

scene_overlay_draw :: proc(s: ^Scene) {
	scene := cast(^SceneOverlay)s

	if !game_is_debug() do return

	rl.DrawFPS(10, 10)
	rl.DrawText(
		strings.clone_to_cstring(utils.typeid_name(scene.tid), context.temp_allocator),
		10,
		30,
		20,
		rl.BLUE,
	)
}
