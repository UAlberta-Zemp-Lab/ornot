# TOBE Optimized Research kNOwledge Toolbox (TOBE ORNOT)

Collection of tools, utilities, and algorithms for use with
Top-Orthogonal-Bottom-Electrode (TOBE) Bias-sensitive Row Column
Arrays

# Core Library

The core helper library for MATLAB is built using the included
build tool. Assuming you have a working C11 toolchain and git
installed (for cloning submodules) it can be built as follows:

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
