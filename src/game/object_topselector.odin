package game

import "core:strings"

import "utils"

import rl "vendor:raylib"


TOP_SEL_PADDING :: [2]f32{20.0, 20.0}
TOP_SEL_SPACING: f32 : 10.0
TOP_SEL_ARROW :: "V"


Top_Selector ::  /* heavy */struct {
	options:      [dynamic]^Top_Selector_Option,
	arrow_hitbox: ^Hitbox,

	// internal
	_pos:         [2]f32,
}

obj_top_selector_create :: proc(option_descs: []Top_Selector_Option_Desc) -> ^Top_Selector {
	selector := new(Top_Selector)

	selector.options = make([dynamic]^Top_Selector_Option)
	for option_desc in option_descs {
		append(&selector.options, obj_top_selector_option_create(option_desc))
	}

	arrow_size := __measure_text(TOP_SEL_ARROW) + TOP_SEL_OPT_PADDING + CST_GUI_THICKNESS
	selector.arrow_hitbox = obj_hitbox_create({0.0, 0.0, arrow_size.x, arrow_size.y})

	return selector
}

obj_top_selector_destroy :: proc(s: ^Top_Selector) {
	obj_hitbox_destroy(s.arrow_hitbox)
	for option in s.options {
		obj_top_selector_option_destroy(option)
	}
	delete(s.options)

	free(s)
}


obj_top_selector_process :: proc(s: ^Top_Selector) {
	if s._pos == {} || rl.IsWindowResized() {
		s._pos.x = (utils.window_size(true) / 2.0 - obj_top_selector_get_size(s) / 2.0).x
		s._pos.y = 0.0
	}
}

obj_top_selector_draw :: proc(s: ^Top_Selector) {
	size := obj_top_selector_get_size(s)
	options_size := obj_top_selector_get_options_size(s)
	options_startpos := (size - options_size) / 2

	rect := transmute(rl.Rectangle)[4]f32{s._pos.x, s._pos.y, size.x, size.y}

	rl.DrawRectangleRec(rect, rl.BLACK)
	rl.DrawRectangleLinesEx(rect, CST_GUI_THICKNESS, rl.WHITE)

	for option in s.options {
		obj_top_selector_option_draw(option, s._pos + options_startpos)
		options_startpos.x += obj_top_selector_option_get_size(option).x + TOP_SEL_SPACING
	}

	__draw_arrow(s)
}


obj_top_selector_get_options_size :: proc(s: ^Top_Selector) -> [2]f32 {
	width, height: f32 = 0.0, -1.0

	for option in s.options {
		size := obj_top_selector_option_get_size(option)
		width += size.x
		height = max(height, size.y)
	}
	width += TOP_SEL_SPACING * f32(len(s.options) - 1)

	return {width, height}
}

obj_top_selector_get_size :: proc(s: ^Top_Selector) -> [2]f32 {
	return obj_top_selector_get_options_size(s) + TOP_SEL_PADDING + CST_GUI_THICKNESS
}


@(private = "file")
__draw_arrow :: proc(s: ^Top_Selector) {
	ts_size := obj_top_selector_get_size(s)
	text_size := __measure_text(TOP_SEL_ARROW)
	size := text_size + TOP_SEL_OPT_PADDING + CST_GUI_THICKNESS
	text_startpos := (size - text_size) / 2.0

	pos := s._pos + {(ts_size.x - size.x) / 2.0, ts_size.y - CST_GUI_THICKNESS}

	s.arrow_hitbox.rect.xy = pos + CST_GUI_THICKNESS_HALF

	rect := transmute(rl.Rectangle){pos.x, pos.y, size.x, size.y}

	rl.DrawRectangleRec(rect, rl.BLACK)
	rl.DrawRectangleLinesEx(rect, CST_GUI_THICKNESS, rl.WHITE)
	rl.DrawTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(TOP_SEL_ARROW, context.temp_allocator),
		pos + text_startpos,
		TOP_SEL_OPT_FONT_SIZE,
		TOP_SEL_OPT_FONT_SPACING,
		rl.WHITE,
	)
	obj_hitbox_queue_debug_draw(s.arrow_hitbox)
}


// ---

TOP_SEL_OPT_PADDING :: [2]f32{10.0, 10.0}
TOP_SEL_OPT_FONT_SIZE :: 12
TOP_SEL_OPT_FONT_SPACING :: 1


Top_Selector_Option_Desc ::  /* desc */struct {
	title: string,
	color: rl.Color,
}

Top_Selector_Option ::  /* heavy */struct {
	title:  string,
	color:  rl.Color,
	hitbox: ^Hitbox,
}

obj_top_selector_option_create :: proc(desc: Top_Selector_Option_Desc) -> ^Top_Selector_Option {
	option := new(Top_Selector_Option)

	option.title = desc.title
	option.color = desc.color

	option_textsize := __measure_text(option.title) + TOP_SEL_OPT_PADDING
	option.hitbox = obj_hitbox_create({0.0, 0.0, option_textsize.x, option_textsize.y})

	return option
}

obj_top_selector_option_destroy :: proc(o: ^Top_Selector_Option) {
	obj_hitbox_destroy(o.hitbox)

	free(o)
}


obj_top_selector_option_draw :: proc(o: ^Top_Selector_Option, pos: [2]f32) {
	o.hitbox.rect.xy = pos + CST_GUI_THICKNESS_HALF

	size := obj_top_selector_option_get_size(o)
	text_size := __measure_text(o.title)
	text_startpos := (size - text_size) / 2
	rect := transmute(rl.Rectangle)[4]f32{pos.x, pos.y, size.x, size.y}

	rl.DrawRectangleRec(rect, rl.ColorBrightness(o.color, -0.67))
	rl.DrawRectangleLinesEx(rect, CST_GUI_THICKNESS, rl.WHITE)
	rl.DrawTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(o.title, context.temp_allocator),
		pos + text_startpos,
		TOP_SEL_OPT_FONT_SIZE,
		TOP_SEL_OPT_FONT_SPACING,
		rl.WHITE,
	)

	obj_hitbox_queue_debug_draw(o.hitbox)
}

obj_top_selector_option_get_size :: proc(o: ^Top_Selector_Option) -> [2]f32 {
	return __measure_text(o.title) + TOP_SEL_OPT_PADDING + CST_GUI_THICKNESS
}


@(private = "file")
__measure_text :: proc(s: string) -> [2]f32 {
	return rl.MeasureTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(s, context.temp_allocator),
		TOP_SEL_OPT_FONT_SIZE,
		TOP_SEL_OPT_FONT_SPACING,
	)
}
