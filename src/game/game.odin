package game

import "core:log"
import "core:strings"
import rl "vendor:raylib"


Game_Desc ::  /* desc */struct {
	width, height: i32,
	title:         string,
	flags:         rl.ConfigFlags,
}
default_game_desc :: proc() -> Game_Desc {
	return {
		width = CST_WINDOW_WIDTH,
		height = CST_WINDOW_HEIGHT,
		title = CST_WINDOW_TITLE,
		flags = CST_WINDOW_FLAGS,
	}
}


Game_Op_Close :: struct {}

Game_Op :: union {
	Game_Op_Close,
}

Game_DebugDraw_Op_Rect :: struct {
	x, y, w, h: f32,
	color:      Maybe(rl.Color),
	camera:     Maybe(rl.Camera2D),
}

Game_DebugDraw_Op_Circle :: struct {
	x, y, r: f32,
	color:   Maybe(rl.Color),
	camera:  Maybe(rl.Camera2D),
}

Game_DebugDraw_Op_Line :: struct {
	x1, y1, x2, y2, thickness: f32,
	color:                     Maybe(rl.Color),
	camera:                    Maybe(rl.Camera2D),
}

Game_DebugDraw_Op :: union {
	Game_DebugDraw_Op_Rect,
	Game_DebugDraw_Op_Circle,
	Game_DebugDraw_Op_Line,
}

Game ::  /* heavy */struct {
	// managers
	director:        ^Director,
	debug_mode:      bool,

	// internal
	_should_close:   bool,
	_deferred_ops:   Deferred(Game_Op),
	_debug_draw_ops: Deferred(Game_DebugDraw_Op),
}

@(private = "file")
__game_st: ^Game = nil

game_init :: proc(desc: Game_Desc) -> bool {
	game := new(Game)
	__game_init_rl(desc)

	game.director = director_create()
	deferred_init(&game._deferred_ops)
	deferred_init(&game._debug_draw_ops)

	__game_st = game
	return true
}

game_term :: proc() {
	deferred_deinit(&__game_st._debug_draw_ops)
	deferred_deinit(&__game_st._deferred_ops)
	director_destroy(__game_st.director)
	__game_st.director = nil

	__game_term_rl()
	free(__game_st)
	__game_st = nil
}


game_run :: proc(start_scene_tid: typeid) {
	g: ^Game
	if g = game_get_singleton(); g == nil {
		log.fatal("game not initialised!")
		return
	}

	if !_director_given_tid_scene_invalid(start_scene_tid) {
		director_goto_now(g.director, start_scene_tid)
	}

	log.info("runtime started")
	loop: for {
		deferred_flush(&g._deferred_ops, g, __game_deferred_flush)

		if rl.WindowShouldClose() do break loop
		if g._should_close do break loop

		// dispatch
		__game_dispatch()

		// process/update everything
		__game_process()

		// draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGRAY)
		__game_draw()
		deferred_flush(&g._debug_draw_ops, g, __game_drawdebug_deferred_flush)
		rl.EndDrawing()
	}
	log.info("runtime ended")
}


game_get_singleton :: proc() -> ^Game {
	return __game_st
}

game_is_debug :: proc() -> bool {
	if g := game_get_singleton(); g != nil {
		return g.debug_mode
	}

	return false
}


game_set_debug :: proc(value: bool) {
	if g := game_get_singleton(); g != nil {
		g.debug_mode = value
	}
}

game_switch_debug :: proc() {
	if g := game_get_singleton(); g != nil {
		game_set_debug(!g.debug_mode)
	}
}

game_queue_debug_draw :: proc(op: Game_DebugDraw_Op) {
	if g := game_get_singleton(); g != nil {
		deferred_push(&g._debug_draw_ops, op)
	}
}


game_close :: proc() {
	if g := game_get_singleton(); g != nil {
		deferred_push(&g._deferred_ops, Game_Op_Close{})
	}
}

game_close_now :: proc() {
	if g := game_get_singleton(); g != nil {
		g._should_close = true
	}
}


@(private = "file")
__game_deferred_flush :: proc(g: ^Game, packed_op: Game_Op) {
	switch op in packed_op {
	case Game_Op_Close:
		game_close_now()
	}
}

@(private = "file")
__game_drawdebug_deferred_flush :: proc(g: ^Game, packed_op: Game_DebugDraw_Op) {
	get_color :: proc(color: Maybe(rl.Color)) -> rl.Color {
		DEFAULT_COLOR :: rl.RED

		return rl.ColorAlpha(color.? or_else DEFAULT_COLOR, 0.42)
	}

	if !game_is_debug() do return

	switch op in packed_op {
	case Game_DebugDraw_Op_Rect:
		color := get_color(op.color)
		rect := rl.Rectangle{op.x, op.y, op.w, op.h}

		if camera, ok := op.camera.?; ok {
			dpi := rl.GetWindowScaleDPI()
			pos := rl.GetWorldToScreen2D({op.x, op.y}, camera)

			screen_rect := rl.Rectangle {
				x      = pos.x / dpi.x,
				y      = pos.y / dpi.y,
				width  = op.w * camera.zoom / dpi.x,
				height = op.h * camera.zoom / dpi.y,
			}
			rl.DrawRectanglePro(screen_rect, {}, camera.rotation, color)
		} else {
			rl.DrawRectangleRec(rect, color)
		}
	case Game_DebugDraw_Op_Circle:
		color := get_color(op.color)

		if camera, ok := op.camera.?; ok {
			dpi := rl.GetWindowScaleDPI()
			pos := rl.GetWorldToScreen2D({op.x, op.y}, camera)

			rl.DrawCircleV({pos.x / dpi.x, pos.y / dpi.y}, op.r * camera.zoom / dpi.x, color)
		} else {
			rl.DrawCircleV({op.x, op.y}, op.r, color)
		}
	case Game_DebugDraw_Op_Line:
		color := get_color(op.color)

		if camera, ok := op.camera.?; ok {
			dpi := rl.GetWindowScaleDPI()
			p1 := rl.GetWorldToScreen2D({op.x1, op.y1}, camera)
			p2 := rl.GetWorldToScreen2D({op.x2, op.y2}, camera)

			rl.DrawLineEx(
				{p1.x / dpi.x, p1.y / dpi.y},
				{p2.x / dpi.x, p2.y / dpi.y},
				op.thickness * camera.zoom / dpi.x,
				color,
			)
		} else {
			rl.DrawLineEx({op.x1, op.y1}, {op.x2, op.y2}, op.thickness, color)
		}
	}
}

@(private = "file")
__game_dispatch :: proc() {
	g := game_get_singleton()

	director_dispatch(g.director)

	director_dispatch_overlay(g.director)
	director_dispatch_current(g.director)
}

@(private = "file")
__game_process :: proc() {
	g := game_get_singleton()

	director_process_current(g.director)
	director_process_overlay(g.director)
}

@(private = "file")
__game_draw :: proc() {
	g := game_get_singleton()

	director_draw_current(g.director)
	director_draw_overlay(g.director)
}

@(private = "file")
__game_init_rl :: proc(desc: Game_Desc) {
	rl.SetConfigFlags(desc.flags)
	rl.InitWindow(
		desc.width,
		desc.height,
		strings.clone_to_cstring(desc.title, context.temp_allocator),
	)
	rl.InitAudioDevice()
	rl.SetExitKey(.KEY_NULL)
}

@(private = "file")
__game_term_rl :: proc() {
	rl.CloseAudioDevice()
	rl.CloseWindow()
}
