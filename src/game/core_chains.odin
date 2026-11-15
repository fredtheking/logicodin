package game

import rl "vendor:raylib"


ChainPositioned :: union {
	^Top_Selector,
	^Button,
	^Hitbox,
}

ChainSized :: union {
	^Hitbox,
}

ChainRected :: union {
	^Hitbox,
}

ChainColored :: union {
	^Button,
	^Hitbox,
}

pos_ :: proc(chain: ChainPositioned, v: [2]f32) -> ChainPositioned {
	switch obj in chain {
	case ^Top_Selector:
		obj._pos = v
	case ^Button:
		obj._pos = v
		pos_(obj.hitbox, v + CST_GUI_THICKNESS_HALF)
	case ^Hitbox:
		obj.rect.xy = v
	}
	return chain
}

size_ :: proc(chain: ChainSized, v: [2]f32) -> ChainSized {
	switch obj in chain {
	case ^Hitbox:
		obj.rect.zw = v
	}
	return chain
}

rect_ :: proc(chain: ChainRected, v: [4]f32) -> ChainRected {
	switch obj in chain {
	case ^Hitbox:
		obj.rect = v
	}
	return chain
}

color_ :: proc(chain: ChainColored, v: [4]u8) -> ChainColored {
	switch obj in chain {
	case ^Button:
		obj.color = rl.Color(v)
	case ^Hitbox:
		obj.color = rl.Color(v)
	}
	return chain
}
