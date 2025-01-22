#!/bin/sh

cflags="-march=native -std=c11 -O3 -Wall -fPIC -shared -Wno-unused-variable"
#cflags="${cflags} -fproc-stat-report"
#cflags="${cflags} -Rpass-missed=.*"

cc=${CC:-cc}

if [ ! -f external/zstd/README.md ] || [ "$(git status --short external/zstd)" ]; then
	git submodule update --init --depth=1 external/zstd
fi

case $(uname -sm) in
MINGW64*) libname="ornot.dll"   ;;
Linux*)   libname="libornot.so" ;;
esac

${cc} ${cflags} -o ${libname} ornot.c
