package game


Deferred ::  /* light */struct($Op: typeid) {
	ops:      [dynamic]Op,
	flushing: bool,
}

deferred_init :: proc(q: ^Deferred($Op), allocator := context.allocator) {
	q.ops = make([dynamic]Op, allocator)
}

deferred_deinit :: proc(q: ^Deferred($Op)) {
	delete(q.ops)
}

deferred_push :: proc(q: ^Deferred($Op), op: Op) {
	append(&q.ops, op)
}

deferred_flush :: proc(q: ^Deferred($Op), user: ^$U, apply: proc(user: ^U, op: Op)) {
	if q.flushing do return
	q.flushing = true
	defer q.flushing = false

	for i := 0; i < len(q.ops); i += 1 {
		apply(user, q.ops[i])
	}
	clear(&q.ops)
}
