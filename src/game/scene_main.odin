package game

import "core:fmt"
import "core:math"
import "core:math/linalg"

import "utils"

import rl "vendor:raylib"


SceneMain :: struct {
	using scene:      Scene,
	look_offset:      [2]f32,
	look_target:      [2]f32,
	look_zoom:        f32,
	look_zoom_target: f32,
	look_rotation:    f32,
	world_mouse_pos:  [2]f32,
	obj_top_selector: ^Top_Selector,
}

scene_main_create :: proc() -> ^Scene {
	scene := new(SceneMain)

	scene.tid = SceneMain
	scene.on_dispatch = scene_main_dispatch
	scene.on_destroy = scene_main_destroy
	scene.on_process = scene_main_process
	scene.on_draw = scene_main_draw

	__scene_main_update_look_offset_from_window_size(scene)
	scene.look_target = {}
	scene.look_zoom = 1.0
	scene.look_zoom_target = 1.0

	scene.obj_top_selector = obj_top_selector_create(
		{
			{title = "wire", color = rl.LIGHTGRAY},
			{title = "not", color = rl.RED},
			{title = "and", color = rl.LIME},
			{title = "or", color = rl.YELLOW},
			{title = "xor", color = rl.ORANGE},
			{title = "battery", color = rl.PURPLE},
		},
	)

	return scene
}

scene_main_dispatch :: proc(s: ^Scene) {
	scene := cast(^SceneMain)s

	if rl.IsWindowResized() {
		__scene_main_update_look_offset_from_window_size(scene)
	}
}

scene_main_destroy :: proc(s: ^Scene) {
	scene := cast(^SceneMain)s

	// ...

	free(scene)
}

scene_main_process :: proc(s: ^Scene) {
	scene := cast(^SceneMain)s

	__scene_main_move_target(scene)
	scene.world_mouse_pos = rl.GetScreenToWorld2D(
		utils.highdpi_mouse_pos(),
		__scene_main_make_camera(scene),
	)

	__scene_main_sanity_checks(scene)
}

scene_main_draw :: proc(s: ^Scene) {
	scene := cast(^SceneMain)s

	__scene_main_draw2d(scene)
	__scene_main_drawui(scene)

	// debug queuing
	camera := __scene_main_make_camera(scene)
	game_queue_debug_draw(
		Game_DebugDraw_Op_Circle {
			x = scene.world_mouse_pos.x,
			y = scene.world_mouse_pos.y,
			r = 6.7,
			color = rl.BLUE,
			camera = camera,
		},
	)
}


@(private = "file")
__scene_main_update_look_offset_from_window_size :: proc(s: ^SceneMain) {
	sizes := utils.window_size()

	s.look_offset = sizes / 2.0
}

@(private = "file")
__scene_main_move_target :: proc(s: ^SceneMain) {
	__scene_main_move_target_keys(s)
	__scene_main_move_target_mouse(s)
}

@(private = "file")
__scene_main_move_target_keys :: proc(s: ^SceneMain) {
	MOVE_SPEED :: 300
	MOVE_SPRINT_MULTIPLIER :: 2.5
	ZOOM_SPEED :: 0.4
	ZOOM_SPRINT_MULTIPLIER :: 2.667

	SPRINT_KEY :: rl.KeyboardKey.LEFT_SHIFT

	// move
	move_vec := [2]f32{}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		move_vec.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		move_vec.x += 1
	}
	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		move_vec.y -= 1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		move_vec.y += 1
	}
	move_vec = linalg.normalize0(move_vec)
	if rl.IsKeyDown(SPRINT_KEY) {
		move_vec *= MOVE_SPRINT_MULTIPLIER
	}


	// zoom
	zoom_add: f32 = 0.0
	if rl.IsKeyDown(.MINUS) || rl.IsKeyDown(.KP_SUBTRACT) {
		zoom_add -= 1
	}
	if rl.IsKeyDown(.EQUAL) || rl.IsKeyDown(.KP_ADD) {
		zoom_add += 1
	}
	if rl.IsKeyDown(SPRINT_KEY) {
		zoom_add *= ZOOM_SPRINT_MULTIPLIER
	}


	// apply
	if move_vec != {} && zoom_add != 0.0 {
		__scene_main_update_look_offset_from_window_size(s)
	}
	deltatime := rl.GetFrameTime()
	s.look_target += move_vec * MOVE_SPEED * deltatime
	s.look_zoom_target *= math.exp(zoom_add * ZOOM_SPEED * deltatime)
}

@(private = "file")
__scene_main_move_target_mouse :: proc(s: ^SceneMain) {
	ZOOM_SPEED :: 13.67

	// move
	move_vec := [2]f32{}
	if rl.IsMouseButtonDown(.MIDDLE) {
		camera := __scene_main_make_camera(s)
		move_vec = -rl.GetMouseDelta() / s.look_zoom * rl.GetWindowScaleDPI()
	}

	// zoom
	zoom_add: f32 = 0.0
	zoom_add += rl.GetMouseWheelMove()

	// apply
	s.look_target += move_vec
	s.look_zoom_target *= math.exp(zoom_add * ZOOM_SPEED * rl.GetFrameTime())
}

@(private = "file")
__scene_main_sanity_checks :: proc(s: ^SceneMain) {
	ZOOM_TRANSLATE_SPEED :: 11.67
	ZOOM_MIN :: 0.1
	ZOOM_MAX :: 80

	s.look_zoom_target = clamp(s.look_zoom_target, ZOOM_MIN, ZOOM_MAX)
	s.look_zoom = linalg.lerp(
		s.look_zoom,
		s.look_zoom_target,
		ZOOM_TRANSLATE_SPEED * rl.GetFrameTime(),
	)
	s.look_rotation = math.wrap(s.look_rotation, 360)
}


@(private = "file")
__scene_main_draw2d :: proc(s: ^SceneMain) {
	g := game_get_singleton()

	rl.BeginMode2D(__scene_main_make_camera(s))
	__scene_main_draw2d_world_grid(s)
	if g.debug_mode {
		__scene_main_draw2d_world_gizmo(s)
	}
	rl.EndMode2D()
}

@(private = "file")
__scene_main_draw2d_world_gizmo :: proc(s: ^SceneMain) {
	LINE_THICK_PIXELS :: 3.67

	tl, br := __scene_main_visible_bounds(s)
	thick := LINE_THICK_PIXELS / s.look_zoom
	thick_half := thick / 2.0

	if tl.y <= 0 && br.y >= 0 {
		rl.DrawLineEx({tl.x, 0}, {br.x, 0}, thick, rl.RED)
	}
	if tl.x <= 0 && br.x >= 0 {
		rl.DrawLineEx({0, tl.y}, {0, br.y}, thick, rl.GREEN)
	}
	rl.DrawRectangleRec({-thick_half, -thick_half, thick, thick}, rl.BLUE)
}

@(private = "file")
__scene_main_draw2d_world_grid :: proc(s: ^SceneMain) {
	MIN_CELL_PIXELS :: 15.0
	LINE_THICK_PIXELS :: 1.0
	LINE_COLOR :: rl.Color{255, 255, 255, 40}

	tl, br := __scene_main_visible_bounds(s)

	cell: f32 = CST_CELL_SIZE
	for cell * s.look_zoom < MIN_CELL_PIXELS {
		cell *= 2
	}

	thick := LINE_THICK_PIXELS / s.look_zoom

	x0 := int(math.floor(tl.x / cell))
	x1 := int(math.ceil(br.x / cell))
	y0 := int(math.floor(tl.y / cell))
	y1 := int(math.ceil(br.y / cell))

	for i in x0 ..= x1 {
		x := f32(i) * cell
		rl.DrawLineEx({x, tl.y}, {x, br.y}, thick, LINE_COLOR)
	}
	for j in y0 ..= y1 {
		y := f32(j) * cell
		rl.DrawLineEx({tl.x, y}, {br.x, y}, thick, LINE_COLOR)
	}
}


@(private = "file")
__scene_main_drawui :: proc(s: ^SceneMain) {
	obj_top_selector_draw(s.obj_top_selector)
}

@(private = "file")
__scene_main_visible_bounds :: proc(s: ^SceneMain) -> (tl, br: [2]f32) {
	size := utils.window_size()
	half := linalg.length(size) / 2.0 / s.look_zoom
	return s.look_target - half, s.look_target + half
}

@(private = "file")
__scene_main_make_camera :: proc(s: ^SceneMain) -> rl.Camera2D {
	return {
		offset = s.look_offset,
		target = s.look_target,
		rotation = s.look_rotation,
		zoom = s.look_zoom,
	}
}
