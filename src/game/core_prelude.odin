package game

import "core:log"


prelude_run :: proc(debug_on_start := false) {
	log.assert(game_init(default_game_desc()), "failed to init game")
	defer game_term()
	game := game_get_singleton()
	game_set_debug(debug_on_start)

	director_set_overlay(game.director, scene_overlay_create())
	director_register(game.director, SceneMain, scene_main_create)

	game_run(SceneMain)
}

prelude_default_logger :: proc() -> log.Logger {
	logger := log_create(.Debug)
	log_hook_rl(logger)
	return logger
}
