#!/bin/sh

cc=${CC:-cc}
wd=${PWD}

machine=$(uname -m)
case ${machine} in
aarch64) target="aarch64"   ;;
x86_64)  target="x86-64-v3" ;;
*) echo "Target Unsupported: $(uname -m)"; exit 1 ;;
esac

case $(uname -sm) in
MINGW64*)
	beamformerlib="submodules/ogl_beamforming/out/ogl_beamformer_lib.dll"
	beamformer="submodules/ogl_beamforming/ogl.exe"
	ornotlib="core/lib/ornot.dll"
	;;
Linux*)
	beamformerlib="submodules/ogl_beamforming/out/ogl_beamformer_lib.so"
	beamformer="submodules/ogl_beamforming/ogl"
	ornotlib="core/lib/libornot.so"
	;;
esac

# NOTE: build ornot
cd "core/lib"
CFLAGS="-march=${target} -O3" ./build.sh
cd "${wd}"

# NOTE: build beamformer
cd "submodules/ogl_beamforming"
${cc} build.c -o build
./build --generic
cd "${wd}"

# NOTE: finalize
outname="beamformer-pack-${machine}-$(git describe --tag)"
mkdir -p "${outname}"
cp "scripts/beamform_simple.m" "${outname}/"
cp "${ornotlib}" "core/lib/ornot.h" "core/lib/zemp_bp.h" "${outname}/"
cp "${beamformerlib}" "submodules/ogl_beamforming/out/ogl_beamformer_lib.h" "${beamformer}" "${outname}/"
cp -r "submodules/ogl_beamforming/assets" "submodules/ogl_beamforming/shaders" "${outname}/"

cp "submodules/ogl_beamforming/LICENSE" "${outname}/LICENSE.ogl_beamforming"
cp "LICENSE" "${outname}/LICENSE.ornot"

zip -r "${outname}.zip" "${outname}"
