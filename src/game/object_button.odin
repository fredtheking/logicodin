package game

import "core:strings"
import rl "vendor:raylib"

BUTTON_FONT_SIZE :: 16
BUTTON_FONT_SPACING :: 1
BUTTON_FONT_PADDING :: [2]f32{16.0, 16.0}


Button ::  /* heavy */struct {
	title:    string,
	color:    rl.Color,
	hitbox:   ^Hitbox,

	// internal
	_pos:     [2]f32,
	_hovered: bool,
}

obj_button_create :: proc(title: string, color := rl.BLACK) -> ^Button {
	button := new(Button)

	button.title = title
	button.color = color

	size := obj_button_get_size(button) - CST_GUI_THICKNESS
	button.hitbox = obj_hitbox_create({0.0, 0.0, size.x, size.y})

	return button
}

obj_button_destroy :: proc(b: ^Button) {
	obj_hitbox_destroy(b.hitbox)

	free(b)
}


obj_button_process :: proc(b: ^Button) {

}

obj_button_draw :: proc(b: ^Button) {
	pos := b._pos
	size := obj_button_get_size(b)
	rect := transmute(rl.Rectangle){pos.x, pos.y, size.x, size.y}
	rl.DrawRectangleRec(rect, rl.ColorBrightness(b.color, -0.67))
	rl.DrawRectangleLinesEx(rect, CST_GUI_THICKNESS, obj_button_get_border_color(b))

	text_startpos := pos + obj_button_get_padding() / 2.0
	rl.DrawTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(b.title, context.temp_allocator),
		text_startpos,
		BUTTON_FONT_SIZE,
		BUTTON_FONT_SPACING,
		rl.WHITE,
	)
	obj_hitbox_queue_debug_draw(b.hitbox)
}


obj_button_get_size :: proc(b: ^Button) -> [2]f32 {
	return _obj_button_measure_text(b.title) + obj_button_get_padding()
}

obj_button_get_border_color :: proc(b: ^Button) -> rl.Color {
	return b._hovered ? rl.LIME : rl.WHITE
}


obj_button_get_padding :: proc() -> [2]f32 {
	return BUTTON_FONT_PADDING + CST_GUI_THICKNESS
}


@(private = "package")
_obj_button_measure_text :: proc(text: string) -> [2]f32 {
	return rl.MeasureTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(text, context.temp_allocator),
		BUTTON_FONT_SIZE,
		BUTTON_FONT_SPACING,
	)
}
