#!/bin/sh

cflags="-march=native -std=c11 -O3 -Wall -fPIC -shared -Wno-unused-variable"
#cflags="${cflags} -fproc-stat-report"
#cflags="${cflags} -Rpass-missed=.*"
cflags="${cflags} -I external/zstd/lib"

cc=${CC:-cc}

# TODO(rnp): adapt to w32 */
if [ ! -f external/zstd/lib/libzstd.a ]; then
	git submodule update --init --depth=1 external/zstd
	CFLAGS="-march=native -O3 -fPIC" make -j -C external/zstd lib-release
fi

case $(uname -sm) in
MINGW64*)
	libname="ornot.dll"
	cp external/zstd/lib/dll/libzstd.dll ./libzstd.dll
	;;
Linux*)
	libname="libornot.so"
	cp external/zstd/lib/libzstd.so.1.5.6 ./libzstd.so
	;;
esac

${cc} ${cflags} -o ${libname} ornot.c ./libzstd*
