package ornot

import "base:intrinsics"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:slice"
import "zbp"

ZbpHeader :: struct {
	ptr: union #shared_nil {
		^zbp.HeaderV1,
		^zbp.HeaderV2,
		^zbp.HeaderV3,
		^zbp.HeaderV4,
	},
	len: u64,
}

get_header :: proc(headerBytes: []byte) -> (header: ZbpHeader, ok: bool) {
	baseHeader := cast(^zbp.BaseHeader)raw_data(headerBytes)
	if baseHeader.magic != zbp.HeaderMagic {
		log.errorf("Byte Magic 0x%X does not match ZBP Magic %X!", baseHeader.magic, zbp.HeaderMagic)
		return
	}
	switch baseHeader.major {
	case 1:
		header = {cast(^zbp.HeaderV1)raw_data(headerBytes[:size_of(zbp.HeaderV1)]), auto_cast len(headerBytes)}
	case 2:
		header = {cast(^zbp.HeaderV2)raw_data(headerBytes[:size_of(zbp.HeaderV2)]), auto_cast len(headerBytes)}
	case 3:
		header = {cast(^zbp.HeaderV3)raw_data(headerBytes[:size_of(zbp.HeaderV3)]), auto_cast len(headerBytes)}
	case 4:
		header = {cast(^zbp.HeaderV4)raw_data(headerBytes[:size_of(zbp.HeaderV4)]), auto_cast len(headerBytes)}
	case:
		log.errorf("Unsupported Major Version Number %d", baseHeader.major)
		ok = false
	}
	ok = true
	return
}

bytes_per_sample :: proc(kind: zbp.DataKind) -> (size: u32, ok := true) {
	switch kind {
	case .Int16, .Float16:
		size = 2
	case .Int16Complex, .Float16Complex:
		size = 4
	case .Float32:
		size = 4
	case .Float32Complex:
		size = 8
	case:
		log.error(fmt.tprintf("Invalid data kind %v", kind))
		ok = false
	}
	return
}

get_header_bytes :: proc(header: ZbpHeader) -> (bytes: []byte) {
	#no_type_assert ptr := header.ptr.(^zbp.HeaderV1)
	bytes = slice.bytes_from_ptr(ptr, auto_cast header.len)
	return
}

get_channel_mapping :: proc(header: ZbpHeader) -> (mapping: []i16, ok := true) {
	switch h in header.ptr {
	case ^zbp.HeaderV1:
		mapping = h.channel_mapping[:h.channel_count]
	case ^zbp.HeaderV2:
		mapping = get_header_offset(header, []i16, h.channel_mapping_offset, h.channel_count) or_return
	case ^zbp.HeaderV3:
		mapping = get_header_offset(header, []i16, h.channel_mapping_offset, h.channel_count) or_return
	case ^zbp.HeaderV4:
		mapping = {}
	}
	return
}

set_channel_mapping :: proc(header: ^ZbpHeader, mapping: []i16, allocator := context.allocator) -> (ok: bool) {
	channel_count: u32
	switch h in header.ptr {
	case ^zbp.HeaderV1:
		channel_count = h.channel_count
	case ^zbp.HeaderV2:
		channel_count = h.channel_count
	case ^zbp.HeaderV3:
		channel_count = h.channel_count
	case ^zbp.HeaderV4:
		if len(mapping) != 0 {
			log.error("Version 4 headers do not support generic channel mappings!")
			return
		}
		return true
	}

	if channel_count != auto_cast len(mapping) {
		log.errorf("Channel count %d does not equal mapping length %d!", channel_count, len(mapping))
		return
	}

	switch h in header.ptr {
	case ^zbp.HeaderV1:
		copy(h.channel_mapping[:h.channel_count], mapping)
	case ^zbp.HeaderV2:
		if header_mapping, header_mapping_ok := get_header_offset(header^, []i16, h.channel_mapping_offset, h.channel_count); header_mapping_ok {
			copy(header_mapping, mapping)
		} else {
			offset := set_header_offset(header, mapping, allocator) or_return
			header.ptr.(^zbp.HeaderV2).channel_mapping_offset = offset
		}
	case ^zbp.HeaderV3:
		if header_mapping, header_mapping_ok := get_header_offset(header^, []i16, h.channel_mapping_offset, h.channel_count); header_mapping_ok {
			copy(header_mapping, mapping)
		} else {
			offset := set_header_offset(header, mapping, allocator) or_return
			header.ptr.(^zbp.HeaderV3).channel_mapping_offset = offset
		}
	case ^zbp.HeaderV4:
		return true
	}
	return
}

get_header_offset :: proc {
	get_header_offset_value,
	get_header_offset_ptr,
	get_header_offset_slice,
}

get_header_offset_value :: proc(
	header: ZbpHeader,
	$T: typeid,
	offset: i32,
) -> (
	value: T,
	ok := true,
) where !intrinsics.type_is_slice(T) &&
	!intrinsics.type_is_pointer(T) {
	value = (get_header_offset(header, ^T, offset) or_return)^
	return
}

get_header_offset_ptr :: proc(header: ZbpHeader, $T: typeid/^$E, offset: i32) -> (value: T, ok: bool) {
	if offset + size_of(E) <= auto_cast header.len {
		if offset >= 0 {
			value = cast(^E)raw_data(get_header_bytes(header)[offset:][:size_of(E)])
		}
		ok = true
		return
	}
	return
}

get_header_offset_slice :: proc(header: ZbpHeader, $T: typeid/[]$E, offset: i32, length: u32) -> (value: T, ok: bool) {
	if offset + cast(i32)length * size_of(E) <= auto_cast header.len {
		if offset >= 0 {
			value = slice.reinterpret([]E, get_header_bytes(header)[offset:][:length * size_of(E)])
		}
		ok = true
		return
	}
	return
}

set_header_offset :: proc {
	set_header_offset_value,
	set_header_offset_ptr,
	set_header_offset_slice,
}

set_header_offset_value :: proc(
	header: ^ZbpHeader,
	value: $T,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	offset: i32,
	ok: bool,
) where !intrinsics.type_is_slice(T) &&
	!intrinsics.type_is_pointer(T) {
	#no_type_assert ptr := cast(^rawptr)&(header.ptr.(^zbp.HeaderV1))
	value_offset := mem.align_forward_int(cast(int)header.len, zbp.OffsetAlignment)
	alloc_error: mem.Allocator_Error
	ptr^, alloc_error = mem.resize(ptr^, auto_cast header.len, value_offset + size_of(T), max(mem.DEFAULT_ALIGNMENT, zbp.OffsetAlignment), allocator, loc)
	if alloc_error != nil {
		log.errorf("Allocation failed: %s!", alloc_error)
		return
	}
	(cast(^T)(cast(uintptr)(ptr^) + uintptr(value_offset)))^ = value
	ok = true
	return
}

set_header_offset_ptr :: proc(header: ^ZbpHeader, value: $T/^$E, allocator := context.allocator, loc := #caller_location) -> (offset: i32, ok: bool) {
	return set_header_offset_value(header, value^, allocator, loc)
}

set_header_offset_slice :: proc(header: ^ZbpHeader, value: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> (offset: i32, ok: bool) {
	#no_type_assert ptr := cast(^rawptr)&(header.ptr.(^zbp.HeaderV1))
	value_offset := mem.align_forward_int(cast(int)header.len, zbp.OffsetAlignment)
	alloc_error: mem.Allocator_Error
	ptr^, alloc_error = mem.resize(
		ptr^,
		auto_cast header.len,
		value_offset + slice.size(value),
		max(mem.DEFAULT_ALIGNMENT, zbp.OffsetAlignment),
		allocator,
		loc,
	)
	if alloc_error != nil {
		log.errorf("Allocation failed: %s!", alloc_error)
		return
	}
	copy(slice.from_ptr(cast([^]E)(cast(uintptr)(ptr^) + uintptr(value_offset)), len(value)), value)
	ok = true
	return
}
