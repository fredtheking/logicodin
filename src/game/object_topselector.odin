package game

import "core:log"
import "core:strings"

import "utils"

import rl "vendor:raylib"


TOP_SEL_SPACING: f32 : 10.0
TOP_SEL_PADDING :: [2]f32{20.0, 20.0}


Top_Selector ::  /* heavy */struct {
	options: [dynamic]^Top_Selector_Option,
}

obj_top_selector_create :: proc(option_descs: []Top_Selector_Option_Desc) -> ^Top_Selector {
	selector := new(Top_Selector)

	selector.options = make([dynamic]^Top_Selector_Option)
	for option_desc in option_descs {
		append(&selector.options, obj_top_selector_option_create(option_desc))
	}

	return selector
}

obj_top_selector_destroy :: proc(s: ^Top_Selector) {
	for option in s.options {
		obj_top_selector_option_destroy(option)
	}
	delete(s.options)

	free(s)
}


obj_top_selector_draw :: proc(s: ^Top_Selector) {
	ARROW_WIDTH :: 100

	size := obj_top_selector_get_options_sizes(s)
	center_x := utils.window_size(ignore_highdpi = true).x / 2.0

	// arrow
	arrow_pos_x := center_x - ARROW_WIDTH / 2.0
	arrow_box := rl.Rectangle {
		arrow_pos_x,
		size.y + TOP_SEL_PADDING.y - CST_GUI_THICKNESS,
		ARROW_WIDTH,
		size.y,
	}

	rl.DrawRectangleRec(arrow_box, rl.BLACK)
	rl.DrawRectangleLinesEx(arrow_box, CST_GUI_THICKNESS, rl.WHITE)

	// options box
	pos_x := center_x - size.x / 2.0 - TOP_SEL_SPACING // have no idea why but this spacing fixes spacing :D
	padded_size := size + TOP_SEL_PADDING
	options_box := rl.Rectangle{pos_x, 0.0, padded_size.x, padded_size.y}

	rl.DrawRectangleRec(options_box, rl.BLACK)
	rl.DrawRectangleLinesEx(options_box, CST_GUI_THICKNESS, rl.WHITE)

	x: f32 = pos_x + TOP_SEL_PADDING.x / 2.0
	for option in s.options {
		obj_top_selector_option_draw(option, {x, TOP_SEL_PADDING.y / 2.0})
		x += obj_top_selector_option_get_boxsize(option).x + TOP_SEL_SPACING
	}

	// arrow line finish
	rl.DrawRectangleRec(
		{
			arrow_box.x + CST_GUI_THICKNESS,
			arrow_box.y,
			arrow_box.width - CST_GUI_THICKNESS * 2,
			CST_GUI_THICKNESS,
		},
		rl.BLACK,
	)
	arrow: string = "V"
	measured_arrow := rl.MeasureTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(arrow, context.temp_allocator),
		TOP_SEL_OPT_FONT_SIZE,
		TOP_SEL_OPT_FONT_SPACING,
	)
	rl.DrawTextCodepoint(
		rl.GetFontDefault(),
		rune(arrow[0]),
		[2]f32 {
			arrow_box.x + (arrow_box.width - measured_arrow.x) / 2.0,
			arrow_box.y + (arrow_box.height - measured_arrow.y) / 2.0 - CST_GUI_THICKNESS * 2.0,
		},
		TOP_SEL_OPT_FONT_SIZE,
		rl.WHITE,
	)
}


obj_top_selector_get_options_sizes :: proc(s: ^Top_Selector) -> [2]f32 {
	width: f32 = 0.0
	height: f32 = -1.0
	for option in s.options {
		size := obj_top_selector_option_get_boxsize(option)
		width += size.x
		height = max(height, size.y)
	}
	width += TOP_SEL_SPACING * f32(len(s.options) - 1)

	return {width, height}
}


// ---

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
	option.hitbox = obj_hitbox_create()

	return option
}

obj_top_selector_option_destroy :: proc(o: ^Top_Selector_Option) {
	obj_hitbox_destroy(o.hitbox)

	free(o)
}


obj_top_selector_option_draw :: proc(o: ^Top_Selector_Option, pos: [2]f32) {
	boxsize := obj_top_selector_option_get_boxsize(o)
	textsize := obj_top_selector_option_get_textsize(o)
	rect := rl.Rectangle{pos.x, pos.y, boxsize.x, boxsize.y}

	rl.DrawRectangleRec(rect, rl.ColorBrightness(o.color, -0.32))
	rl.DrawRectangleLinesEx(rect, CST_GUI_THICKNESS, rl.WHITE)
	rl.DrawTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(o.title, context.temp_allocator),
		pos + boxsize / 2 - textsize / 2,
		TOP_SEL_OPT_FONT_SIZE,
		TOP_SEL_OPT_FONT_SPACING,
		rl.WHITE,
	)
}


obj_top_selector_option_get_textsize :: proc(o: ^Top_Selector_Option) -> [2]f32 {
	return rl.MeasureTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(o.title, context.temp_allocator),
		TOP_SEL_OPT_FONT_SIZE,
		TOP_SEL_OPT_FONT_SPACING,
	)
}

obj_top_selector_option_get_boxsize :: proc(o: ^Top_Selector_Option) -> [2]f32 {
	PADDING :: [2]f32{16.0, 16.0}

	return obj_top_selector_option_get_textsize(o) + PADDING
}
