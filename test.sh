#!/bin/bash
set -e
SECONDS=0

DEFCONFIG="vendor/fog-perf_defconfig"
CORES=${CORES:-$(nproc --all)}

TC_DIR="$(pwd)/tc/gcc-aarch64"
OUT_DIR="$(pwd)/out"

# Set Environtment
export PATH="$TC_DIR/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export KBUILD_BUILD_USER="Rin"
export KBUILD_BUILD_HOST="Anomaly-arc"

# Clean logic
if [[ "$1" == "-c" || "$1" == "--clean" ]]; then
    echo "[*] Cleaning kernel output"
    rm -rf "$OUT_DIR"
    make mrproper
    exit 0
fi

mkdir -p "$OUT_DIR"

# Generate Config
if [[ ! -f "$OUT_DIR/.config" ]]; then
    echo "[*] Generating defconfig: $DEFCONFIG"
    make O="$OUT_DIR" $DEFCONFIG
fi

echo "[*] Starting compilation Kernmoon (-j$CORES)..."

# 1. Build Kernel & DTBs (Target dtbs biar file .dtbo mentah ke-generate)
nice -n 5 ionice -c2 -n7 \
make -j$CORES O="$OUT_DIR" Image.gz dtbs

KERNEL_IMAGE="$OUT_DIR/arch/arm64/boot/Image.gz"

# 2. Logic pembuatan dtbo.img (Bypass make dtboimage yang sering bikin Python mogok)
echo "[*] Creating dtbo.img with Python..."
DTBO_SOURCE="$OUT_DIR/arch/arm64/boot/dts/vendor/qcom/fog-khaje-idp-nopmi-overlay.dtbo"
MKDTBOIMG="scripts/dtc/libufdt/utils/src/mkdtboimg.py"

if [[ -f "$DTBO_SOURCE" ]]; then
    # Kita panggil python3 secara eksplisit buat bungkus 1 file itu jadi .img
    python3 "$MKDTBOIMG" create "$OUT_DIR/dtbo.img" "$DTBO_SOURCE"
    echo "[*] dtbo.img successfully created!"
else
    echo "[!] Warning: File .dtbo mentah gak ketemu, skip bikin .img"
fi

# Final Check
if [[ -f "$KERNEL_IMAGE" ]]; then
    echo "====================================="
    echo "   COMPILE SUCCESSFUL - RIN EDITION"
    echo "   Time  : $((SECONDS/60))m $((SECONDS%60))s"
    echo "   Kernel: $KERNEL_IMAGE"
    [[ -f "$OUT_DIR/dtbo.img" ]] && echo "   DTBO  : $OUT_DIR/dtbo.img"
    echo "====================================="
else
    echo "Compilation failed."
    exit 1
fi
