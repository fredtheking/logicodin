package build

import "core:fmt"
import "core:log"
import "core:os"
import "core:slice"
import "core:strings"

GAME_PATH :: "bin/game"


// --run (runs executable right after build)
main :: proc() {
	context.logger = log.create_console_logger()
	context.logger.options = {.Terminal_Color, .Level}

	run(fmt.tprintf("odin build src -debug -out:%s", GAME_PATH))

	log.info("successful build")
	free_all(context.temp_allocator)

	if slice.contains(os.args, "--run") {
		run(GAME_PATH)
	} else {
		log.info(
			"to start game immediately after build: pass `--run` flag when calling this `build.odin` file",
		)
	}
}


// ---


run :: proc {
	run_from_string,
	run_from_slice,
}
run_from_string :: proc(cmd: string) {
	run_from_slice(strings.split(cmd, " "))
}
run_from_slice :: proc(cmds: []string) {
	log.infof("running %s", cmds)
	exit_code, err := exec(cmds)
	if err != nil {
		log.errorf("failed to execute a process (error was thrown): %s", err)
		os.exit(1)
	}

	if exit_code != 0 {
		log.errorf("failed to execute a process (non-zero exit_code): %d", exit_code)
		os.exit(1)
	}
}

exec :: proc(cmds: []string) -> (exit_code: int, err: os.Error) {
	process := os.process_start(
		{command = cmds, stdin = os.stdin, stdout = os.stdout, stderr = os.stderr},
	) or_return
	state := os.process_wait(process) or_return
	return state.exit_code, nil
}

check :: proc(name: string) -> bool {
	process, err := os.process_start({command = {name, "--version"}})
	if err != nil {
		return false
	}
	_, _ = os.process_wait(process)
	return true
}
