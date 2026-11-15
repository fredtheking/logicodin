package game

import "core:math"

import "utils"

import rl "vendor:raylib"


TOP_SEL_PADDING :: [2]f32{20.0, 20.0}
TOP_SEL_SPACING: f32 : 10.0
TOP_SEL_ARROW :: "    V    V    V    "
TOP_SEL_Y_LERP_TIME :: 26.78


Top_Selector_Option_Desc ::  /* desc */struct {
	title: string,
	color: rl.Color,
}

Top_Selector ::  /* heavy */struct {
	options: [dynamic]^Button,
	arrow:   ^Button,

	// internal
	_shown:  bool,
	_pos:    [2]f32,
}

obj_top_selector_create :: proc(option_descs: []Top_Selector_Option_Desc) -> ^Top_Selector {
	selector := new(Top_Selector)

	selector.options = make(type_of(selector.options))
	for option_desc in option_descs {
		append(&selector.options, obj_button_create(option_desc.title, option_desc.color))
	}
	selector.arrow = obj_button_create(TOP_SEL_ARROW)

	selector._shown = true

	return selector
}

obj_top_selector_destroy :: proc(s: ^Top_Selector) {
	obj_button_destroy(s.arrow)
	for option in s.options {
		obj_button_destroy(option)
	}
	delete(s.options)

	free(s)
}


obj_top_selector_process :: proc(s: ^Top_Selector) {
	if s._pos == {} || rl.IsWindowResized() {
		s._pos.x = (utils.window_size(true) / 2.0 - obj_top_selector_get_size(s) / 2.0).x
	}

	if rl.IsKeyPressed(.TAB) do s._shown = !s._shown // TODO: remove from here

	target_y := s._shown ? 0 : -obj_top_selector_get_size(s).y
	s._pos.y = math.lerp(s._pos.y, target_y, TOP_SEL_Y_LERP_TIME * rl.GetFrameTime())

	options_startpos := s._pos + obj_top_selector_get_padding() / 2.0
	for &option in s.options {
		pos_(option, options_startpos)
		options_startpos.x += obj_button_get_size(option).x + TOP_SEL_SPACING
	}

	size := obj_top_selector_get_size(s)
	arrow_startpos := [2]f32 {
		s._pos.x + (size.x - obj_button_get_size(s.arrow)).x / 2.0,
		s._pos.y + size.y - CST_GUI_THICKNESS * 2,
	}
	pos_(s.arrow, arrow_startpos)
}

obj_top_selector_draw :: proc(s: ^Top_Selector) {
	size := obj_top_selector_get_size(s)
	options_size := obj_top_selector_get_options_size(s)
	options_startpos := (size - options_size) / 2

	rect := transmute(rl.Rectangle)[4]f32{s._pos.x, s._pos.y, size.x, size.y}

	rl.DrawRectangleRec(rect, rl.BLACK)
	rl.DrawRectangleLinesEx(rect, CST_GUI_THICKNESS, rl.WHITE)

	for option in s.options {
		obj_button_draw(option)
	}
	obj_button_draw(s.arrow)
}


obj_top_selector_get_options_size :: proc(s: ^Top_Selector) -> [2]f32 {
	width, height: f32 = 0.0, -1.0

	for option in s.options {
		size := obj_button_get_size(option)
		width += size.x
		height = max(height, size.y)
	}
	width += TOP_SEL_SPACING * f32(len(s.options) - 1)

	return {width, height}
}

obj_top_selector_get_size :: proc(s: ^Top_Selector) -> [2]f32 {
	return obj_top_selector_get_options_size(s) + obj_top_selector_get_padding()
}

obj_top_selector_get_padding :: proc() -> [2]f32 {
	return TOP_SEL_PADDING + CST_GUI_THICKNESS
}
