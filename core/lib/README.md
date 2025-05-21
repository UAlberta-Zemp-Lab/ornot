# ornot core

## Building

### Core Library
Assuming you have a working C toolchain on the path as well as git
(for cloning submodules):

```
./build.sh
```

### Mex Zstd Decompressor

```matlab
cd path/to/ornot/core/lib
mex -Iexternal/zstd/lib ornot_zstd_decompress_mex.c libzstd.a
```

### Mex Beamform Parameters Loader

```matlab
cd path/to/ornot/core/lib
mex ornot_bp_load_mex.c
```

## Usage

See the [API Documentation](./API.md) for usage details.
