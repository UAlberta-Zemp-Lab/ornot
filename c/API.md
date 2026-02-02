# API

### `b32 write_data_with_zstd_compression(char *output_name, void *data, u64 data_size)`

Compresses `data` using [zstd][], and writes the result to
`output_name`. The caller is responsible for adding the `.zst`
extension as required by their environment. Returns whether the
operation succeeded.

### `b32 unpack_zstd_compressed_data(char *input_file, void *output, size_t output_size)`

Reads input file (assumed to be zstandard compressed) and
decompresses it into buffer. Buffer size can be determined from
the zemp_bp header. You should not use this from anything other
than a MATLAB or Python script.

## MATLAB (Mex)

### `out = ornot_zstd_decompress_mex(in)`

Decompresses 1D `uint8` data `in` to `int16` array `out`. The
function will error if these constraints are not met.

[zstd]: https://facebook.github.io/zstd/
