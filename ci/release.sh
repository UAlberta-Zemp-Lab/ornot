#!/bin/sh

cc=${CC:-cc}
wd=${PWD}

machine=$(uname -m)
case ${machine} in
aarch64) target="armv8"     ;;
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

# NOTE: readme
cat << EOF >| "${outname}/README.txt"
HOW TO USE

1. Download previously acquired data and put it somewhere accesible.
2. Launch the beamformer (ogl.exe).
3. Open beamform_simple.m in MATLAB and point it to the data files.
4. Modify number of output points and axial and lateral regions as desired.
5. Run. The beamformed figure will be visible in the beamformer and in a MATLAB figure.

TROUBLESHOOTING

MATLAB is stalled or doesn't seem to be doing anything.
-> Force close MATLAB and start from the top.
EOF

zip -r "${outname}.zip" "${outname}"
