#!/bin/bash
# script BY: anomaly_arc
SECONDS=0 
DEFCONFIG="vendor/fog-perf_defconfig"
export KBUILD_BUILD_USER="Filia"
export KBUILD_BUILD_HOST="Quantum-world⚛"
export ARCH=arm64
export SUBARCH=arm64
TC_DIR="$(pwd)/../android_prebuilts_clang-standalone"
export PATH="$TC_DIR/bin:$PATH"
export USE_CCACHE=1
# export CCACHE_DIR="/media/filia/DiskB/.ccache"
export CC="ccache clang"

if [[ $1 = "-c" || $1 = "--clean" ]]; then
        echo "Cleaning up out folder..."
        rm -rf out
fi

mkdir -p out
echo -e "\nGenerating defconfig: $DEFCONFIG"
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation on 4 Cores (-j4) via LLVM..."
make -j4 O=out \
     ARCH=arm64 \
     SUBARCH=arm64 \
     LLVM=1 \
     LLVM_IAS=1 \
     CLANG_TRIPLE=aarch64-linux-gnu- \
     CROSS_COMPILE=aarch64-linux-gnu- \
     Image.gz dtbs

kernel="out/arch/arm64/boot/Image.gz"
dtb_dir="out/arch/arm64/boot/dts/vendor/qcom"
output_final="out/Image.gz-dtb"
dtb="out"

if [ -f "$kernel" ]; then
        echo -e "\n====================================="
        echo -e "COMPILE SUCCESSFUL"
        echo -e "Compilation Time: $((SECONDS / 60)) minute $((SECONDS % 60)) second"
        echo -e "-------------------------------------"
        
        cat "$dtb_dir"/*.dtb > "$dtb/dtb_combined"     
        if [ -d "$dtb_dir" ] && [ "$(ls -A $dtb_dir/*.dtb 2>/dev/null)" ]; then
                cat "$kernel" $dtb/dtb_combined > "$output_final"
                echo -e "EXTRACT & MERGE PROCESS SUCCESSFUL!"
                echo -e "Flash Ready Final Result: $output_final"
        else
                echo -e "Warning: .dtb file not found in $dtb_dir"
                echo -e "Failed to create Image.gz-dtb, please check your dts configuration."
        fi
        echo -e "====================================="
else
        echo "Compilation Failed!"
        exit 1
fi
