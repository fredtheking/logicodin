package game

import "base:runtime"
import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:log"
import "core:path/filepath"

import rl "vendor:raylib"


log_create :: proc(lowest_level := log.Level.Debug) -> log.Logger {
	return log.Logger {
		procedure = __log_proc,
		lowest_level = lowest_level,
		options = {.Terminal_Color},
	}
}

log_hook_rl :: proc(logger: log.Logger) {
	__log_rl_logger = logger

	rl.SetTraceLogLevel(__log_level_to_rl(logger.lowest_level))
	rl.SetTraceLogCallback(__log_rl_callback)
}


@(private = "file")
__LOG_LINE_WIDTH :: 4
@(private = "file")
__LOG_COLUMN_WIDTH :: 3
@(private = "file")
__LOG_DASHES :: "--------"
@(private = "file")
__LOG_RL_BUFFER_SIZE :: 1024

@(private = "file")
__ANSI_RESET :: "\x1b[0m"
@(private = "file")
__ANSI_DIM :: "\x1b[2m"
@(private = "file")
__ANSI_CYAN :: "\x1b[36m"
@(private = "file")
__ANSI_MAGENTA :: "\x1b[35m"
@(private = "file")
__ANSI_GREEN :: "\x1b[32m"
@(private = "file")
__ANSI_YELLOW :: "\x1b[33m"
@(private = "file")
__ANSI_RED :: "\x1b[31m"
@(private = "file")
__ANSI_FATAL :: "\x1b[1;41m"

@(private = "file")
__log_proc :: proc(
	data: rawptr,
	level: log.Level,
	text: string,
	options: log.Options,
	location := #caller_location,
) {
	name, level_col := __log_level_style(level)
	msg_col := level >= .Warning ? level_col : ""
	reset, dim, file_col := __ANSI_RESET, __ANSI_DIM, __ANSI_CYAN

	if .Terminal_Color not_in options {
		level_col, msg_col, reset, dim, file_col = "", "", "", "", ""
	}

	file := filepath.stem(filepath.base(location.file_path))

	if location.line == 0 {
		fmt.eprintf(
			"%s%s%s %s> [%s:%s]%s %s%s%s: %s%s%s\n",
			level_col,
			name,
			reset,
			dim,
			__LOG_DASHES[:__LOG_LINE_WIDTH],
			__LOG_DASHES[:__LOG_COLUMN_WIDTH],
			reset,
			file_col,
			file,
			reset,
			msg_col,
			text,
			reset,
		)
		return
	}

	fmt.eprintf(
		"%s%s%s %s> [%0*d:%0*d]%s %s%s%s: %s%s%s\n",
		level_col,
		name,
		reset,
		dim,
		__LOG_LINE_WIDTH,
		location.line,
		__LOG_COLUMN_WIDTH,
		location.column,
		reset,
		file_col,
		file,
		reset,
		msg_col,
		text,
		reset,
	)
}

@(private = "file")
__log_level_style :: proc(level: log.Level) -> (name, color: string) {
	switch {
	case level < .Info:
		return "DEBUG", __ANSI_MAGENTA
	case level < .Warning:
		return "INFO ", __ANSI_GREEN
	case level < .Error:
		return "WARN ", __ANSI_YELLOW
	case level < .Fatal:
		return "ERROR", __ANSI_RED
	}
	return "FATAL", __ANSI_FATAL
}


// --- raylib

@(private = "file")
__log_rl_logger: log.Logger

@(private = "file")
__log_rl_callback :: proc "c" (rl_level: rl.TraceLogLevel, text: cstring, args: ^c.va_list) {
	context = runtime.default_context()
	context.logger = __log_rl_logger

	buf: [__LOG_RL_BUFFER_SIZE]u8
	n := libc.vsnprintf(raw_data(buf[:]), len(buf), text, args)
	if n < 0 do return

	msg := string(buf[:min(int(n), len(buf) - 1)])
	location := runtime.Source_Code_Location {
		file_path = "raylib",
	}
	log.log(__log_level_from_rl(rl_level), msg, location = location)
}

@(private = "file")
__log_level_to_rl :: proc(level: log.Level) -> rl.TraceLogLevel {
	switch {
	case level < .Info:
		return .DEBUG
	case level < .Warning:
		return .INFO
	case level < .Error:
		return .WARNING
	case level < .Fatal:
		return .ERROR
	}
	return .FATAL
}

@(private = "file")
__log_level_from_rl :: proc(level: rl.TraceLogLevel) -> log.Level {
	#partial switch level {
	case .ALL, .TRACE, .DEBUG:
		return .Debug
	case .INFO:
		return .Info
	case .WARNING:
		return .Warning
	case .ERROR:
		return .Error
	}
	return .Fatal
}
