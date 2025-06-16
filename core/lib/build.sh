#!/bin/sh

cflags="${CFLAGS:--march=native -O3}"
cflags="${cflags} -std=c11 -Wall -fPIC -Wno-unused-variable"
#cflags="${cflags} -fproc-stat-report"
#cflags="${cflags} -Rpass-missed=.*"
cflags="${cflags} -Iexternal/zstd/lib"

cc=${CC:-cc}

zstd="libzstd.a"
case $(uname -sm) in
MINGW64*) libname="ornot.dll"   ;;
Linux*)   libname="libornot.so" ;;
Darwin*)  libname="ornot.dylib" ;;
esac

build_zstd()
{
	src=external/zstd/lib
	dst=out/zstd
	mkdir -p ${dst}

	${cc} ${cflags} -c ${src}/common/debug.c                      -o ${dst}/debug.o
	${cc} ${cflags} -c ${src}/common/entropy_common.c             -o ${dst}/entropy_common.o
	${cc} ${cflags} -c ${src}/common/error_private.c              -o ${dst}/error_private.o
	${cc} ${cflags} -c ${src}/common/fse_decompress.c             -o ${dst}/fse_decompress.o
	${cc} ${cflags} -c ${src}/common/pool.c                       -o ${dst}/pool.o
	${cc} ${cflags} -c ${src}/common/threading.c                  -o ${dst}/threading.o
	${cc} ${cflags} -c ${src}/common/xxhash.c                     -o ${dst}/xxhash.o
	${cc} ${cflags} -c ${src}/common/zstd_common.c                -o ${dst}/zstd_common.o
	${cc} ${cflags} -c ${src}/compress/fse_compress.c             -o ${dst}/fse_compress.o
	${cc} ${cflags} -c ${src}/compress/hist.c                     -o ${dst}/hist.o
	${cc} ${cflags} -c ${src}/compress/huf_compress.c             -o ${dst}/huf_compress.o
	${cc} ${cflags} -c ${src}/compress/zstd_compress.c            -o ${dst}/zstd_compress.o
	${cc} ${cflags} -c ${src}/compress/zstd_compress_literals.c   -o ${dst}/zstd_compress_literals.o
	${cc} ${cflags} -c ${src}/compress/zstd_compress_sequences.c  -o ${dst}/zstd_compress_sequences.o
	${cc} ${cflags} -c ${src}/compress/zstd_compress_superblock.c -o ${dst}/zstd_compress_superblock.o
	${cc} ${cflags} -c ${src}/compress/zstd_double_fast.c         -o ${dst}/zstd_double_fast.o
	${cc} ${cflags} -c ${src}/compress/zstd_fast.c                -o ${dst}/zstd_fast.o
	${cc} ${cflags} -c ${src}/compress/zstd_lazy.c                -o ${dst}/zstd_lazy.o
	${cc} ${cflags} -c ${src}/compress/zstd_ldm.c                 -o ${dst}/zstd_ldm.o
	${cc} ${cflags} -c ${src}/compress/zstd_opt.c                 -o ${dst}/zstd_opt.o
	${cc} ${cflags} -c ${src}/compress/zstdmt_compress.c          -o ${dst}/zstdmt_compress.o
	${cc} ${cflags} -c ${src}/compress/zstd_preSplit.c            -o ${dst}/zstd_preSplit.o
	${cc} ${cflags} -c ${src}/decompress/huf_decompress_amd64.S   -o ${dst}/huf_decompress_amd64.o
	${cc} ${cflags} -c ${src}/decompress/huf_decompress.c         -o ${dst}/huf_decompress.o
	${cc} ${cflags} -c ${src}/decompress/zstd_ddict.c             -o ${dst}/zstd_ddict.o
	${cc} ${cflags} -c ${src}/decompress/zstd_decompress.c        -o ${dst}/zstd_decompress.o
	${cc} ${cflags} -c ${src}/decompress/zstd_decompress_block.c  -o ${dst}/zstd_decompress_block.o

	ar rc ${zstd} "${dst}"/*.o
}

if [ $(git diff-index --quiet HEAD -- external/zstd) ]; then
	git submodule update --init --depth=1 external/zstd
fi

[ "./build.sh" -nt "${zstd}" ] || [ ! -f ${zstd} ] && build_zstd

${cc} ${cflags} -shared -o ${libname} ornot.c ${zstd}
