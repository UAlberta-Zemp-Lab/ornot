# API

## MATLAB

The following functions are only really useful in MATLAB and
should probably not be used elsewhere (they are all trivial to
implement in a real language).

### `b32 write_zemp_bp_v1(char *output_file, zemp_bp_v1 *header)`

Writes `header` to binary file `output_file` which will be created
and truncated. Returns whether the function was successful.

### `b32 unpack_zemp_bp_v1(char *input_file, zemp_bp_v1 *output_header)`

Reads `input_file`, checks if it looks like a `zemp_bp_v1` header,
and fills `output_header` if it does. Returns whether the function
was successful.

Example:
```matlab
% make an empty bp struct so that MATLAB can control the memory
bp = libstruct("zemp_bp_v1", struct());
% fill in the struct
result = calllib("ornot", "unpack_zemp_bp_v1", file_path, bp);
% convert back to MATLAB struct
bp = struct(bp);
```

### `b32 write_i16_data_compressed(char *output_name, i16 *data, u32 data_element_count)`

Compresses `data` using [zstd][], and writes the result to
`output_name`. The caller is responsible for adding the `.zst`
extension as required by their environment. Returns whether the
operation succeeded.

### `b32 unpack_compressed_i16_data(char *input_file, void *output, size_t output_size)`

Reads input file (assumed to be zstandard compressed) and
decompresses it into buffer. Buffer size can be determined from
the zemp_bp header. You should not use this from anything other
than a MATLAB script.

## MATLAB (Mex)

### `out = ornot_zstd_decompress_mex(in)`

Decompresses 1D `uint8` data `in` to `int16` array `out`. The
function will error if these constraints are not met.

[zstd]: https://facebook.github.io/zstd/
