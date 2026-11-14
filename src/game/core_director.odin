package game

import "core:log"

import "utils"


Director_Op_Goto :: struct {
	tid: typeid,
}

Director_Op :: union {
	Director_Op_Goto,
}

Director ::  /* heavy */struct {
	current:      ^Scene,
	overlay:      ^Scene,
	creators:     map[typeid]Scene_Creator_Proc,
	deferred_ops: Deferred(Director_Op),
}

director_create :: proc() -> ^Director {
	director := new(Director)

	director.current = nil
	director.creators = make(map[typeid]Scene_Creator_Proc)
	deferred_init(&director.deferred_ops)

	return director
}

director_destroy :: proc(d: ^Director) {
	if d.overlay != nil do director_set_overlay(d, nil)

	deferred_deinit(&d.deferred_ops)
	delete(d.creators)
	director_unload(d)

	free(d)
}

director_dispatch :: proc(d: ^Director) {
	deferred_flush(&d.deferred_ops, d, __deferred_flush)
}

director_register :: proc(d: ^Director, key: typeid, value: Scene_Creator_Proc) -> bool {
	if _director_given_tid_scene_invalid(key) {
		log.errorf("scene registration failed, check error above: %s", utils.typeid_name(key))
		return false
	}

	d.creators[key] = value
	return true
}

director_unload :: proc(d: ^Director) {
	if d.current == nil do return

	d.current->on_destroy()
	d.current = nil
	log.debug("unloaded scene")
}

director_load :: proc(d: ^Director, tid: typeid) -> bool {
	if d.current != nil {
		log.errorf(
			"cannot replace current scene from `%s` to `%s` (maybe you meant `director_goto`/`director_goto_now`?",
			utils.typeid_name(d.current.tid),
			utils.typeid_name(tid),
		)
		return false
	}

	if _director_given_tid_scene_invalid(tid) do return false

	d.current = d.creators[tid]()
	log.debugf("loaded scene: %s", utils.typeid_name(d.current.tid))
	return true
}

director_set_overlay :: proc(d: ^Director, scene: ^Scene) {
	if d.overlay != nil {
		d.overlay->on_destroy()
		d.overlay = nil
	}

	d.overlay = scene

	if scene == nil do log.debug("cleared overlay")
	else do log.debugf("set overlay: %s", utils.typeid_name(scene.tid))
}


director_goto :: proc(d: ^Director, tid: typeid) {
	if _director_given_tid_scene_invalid(tid) do return

	deferred_push(&d.deferred_ops, Director_Op_Goto{tid = tid})
}

director_goto_now :: proc(d: ^Director, tid: typeid) {
	director_unload(d)
	director_load(d, tid)
}


director_dispatch_current :: proc(d: ^Director) {
	scene := d.current
	if scene == nil do return

	if scene.on_dispatch != nil do scene->on_dispatch()
}

director_process_current :: proc(d: ^Director) {
	scene := d.current
	if scene == nil do return

	if scene.on_process != nil do scene->on_process()
}

director_draw_current :: proc(d: ^Director) {
	scene := d.current
	if scene == nil do return

	if scene.on_draw != nil do scene->on_draw()
}

director_dispatch_overlay :: proc(d: ^Director) {
	scene := d.overlay
	if scene == nil do return

	if scene.on_dispatch != nil do scene->on_dispatch()
}

director_process_overlay :: proc(d: ^Director) {
	scene := d.overlay
	if scene == nil do return

	if scene.on_process != nil do scene->on_process()
}

director_draw_overlay :: proc(d: ^Director) {
	scene := d.overlay
	if scene == nil do return

	if scene.on_draw != nil do scene->on_draw()
}


@(private = "package")
_director_given_tid_scene_invalid :: proc(tid: typeid) -> bool {
	if utils.is_or_inherits(tid, Scene) do return false

	log.errorf("provided tid does not inherit `Scene` struct")
	return true
}

@(private = "file")
__deferred_flush :: proc(d: ^Director, packed_op: Director_Op) {
	switch op in packed_op {
	case Director_Op_Goto:
		director_goto_now(d, op.tid)
	}
}


// ---

Scene_Method_Proc :: #type proc(scene: ^Scene)
Scene_Creator_Proc :: #type proc() -> ^Scene

Scene ::  /* heavy */struct {
	tid:         typeid,
	on_destroy:  Scene_Method_Proc,
	on_dispatch: Scene_Method_Proc,
	on_process:  Scene_Method_Proc,
	on_draw:     Scene_Method_Proc,
}
