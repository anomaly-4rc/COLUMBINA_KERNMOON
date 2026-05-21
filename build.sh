#!/bin/bash
set -e
SECONDS=0

DEFCONFIG="vendor/fog-perf_defconfig"
CORES=${CORES:-$(nproc)}

OUT_DIR="$(pwd)/out"

export ARCH=arm64
export SUBARCH=arm64

export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

export HOSTCC=gcc
export HOSTCXX=g++
export LD=aarch64-linux-gnu-ld
export KBUILD_BUILD_USER="Filia-Lunae"
export KBUILD_BUILD_HOST="Luna-Arch-X86"

if [[ "$1" == "-c" || "$1" == "--clean" ]]; then
    echo "[*] Cleaning kernel output"
    rm -rf "$OUT_DIR"
    make mrproper
    exit 0
fi

mkdir -p "$OUT_DIR"

if [[ ! -f "$OUT_DIR/.config" ]]; then
    echo "[*] Generating defconfig: $DEFCONFIG"
    make O="$OUT_DIR" $DEFCONFIG
    make O="$OUT_DIR" olddefconfig
fi

echo "[*] Starting compilation (-j$CORES)..."

nice -n 5 ionice -c2 -n7 \
make -j$CORES \
     O="$OUT_DIR" \
     Image.gz dtbs
# RESULT
KERNEL_IMAGE="$OUT_DIR/arch/arm64/boot/Image.gz"
DTB_DIR="$OUT_DIR/arch/arm64/boot/dts/vendor/qcom"

if [[ -f "$KERNEL_IMAGE" ]]; then
    echo "====================================="
    echo "✅ COMPILE SUCCESSFUL"
   
    echo "[*] Combining DTBs..."
cat "$DTB_DIR"/*.dtb > "$OUT_DIR/dtb_combined"

    echo "[*] Creating Image.gz-dtb..."
    cat "$KERNEL_IMAGE" "$OUT_DIR/dtb_combined" > "$OUT_DIR/Image.gz-dtb"
    
    echo "Time: $((SECONDS/60))m $((SECONDS%60))s"
    echo "Final Kernel: $OUT_DIR/Image.gz-dtb"
    echo "====================================="
else
    echo "❌ Compilation failed."
    exit 1
fi