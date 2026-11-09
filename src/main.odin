package main

import "game"


main :: proc() {
	context.logger = game.prelude_default_logger()
	game.prelude_run(debug_on_start = true)
}
