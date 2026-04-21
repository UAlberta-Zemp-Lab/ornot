# TOBE Optimized Research kNOwledge Toolbox (TOBE ORNOT)

Collection of tools, utilities, and algorithms for use with
Top-Orthogonal-Bottom-Electrode (TOBE) Bias-sensitive Row Column
Arrays

# Releases

The [Releases][] tab provides portable releases suitable for
running on any Windows system. They are built using the
[`release.sh`](./ci/release.sh) script. To build a packaged
version optimized for your local system (Windows or Linux) the
script may be run directly:

```sh
./ci/release.sh
```

The resulting `beamformer-pack-*` folder can be copied elsewhere
and used directly.

## Dependencies

* C11 Toolchain
* git (for cloning submodules)

# Core Library

The core helper library is built using the included build tool.
It can be built as follows:

```sh
cc -march=native -O3 -fms-extensions build.c -o build
./build
```

### Mex Zstd Decompressor

There is also a mex function for decompressing zstd data from
MATLAB. It needs to be compiled in MATLAB with the mex function:

```matlab
cd path/to/ornot
mex -Ic/external/zstd/lib c/ornot_zstd_decompress_mex.c out/zstd.a
```

## API Documenation
See the [API Documentation](./c/API.md) for usage details.

[Releases]: https://github.com/UAlberta-Zemp-Lab/ornot/releases
