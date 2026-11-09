package utils

import "base:runtime"
import "core:reflect"


is_or_inherits :: proc(tid, base: typeid) -> bool {
	if tid == base {
		return true
	}

	for f in reflect.struct_fields_zipped(tid) {
		if f.is_using && is_or_inherits(f.type.id, base) {
			return true
		}
	}

	return false
}

typeid_name :: proc(tid: typeid) -> (string, bool) #optional_ok {
	info := type_info_of(tid)
	if info == nil do return "", false

	if name_var, ok := info.variant.(runtime.Type_Info_Named); ok {
		return name_var.name, true
	}

	return "", false
}
