#!/bin/bash
set -e
SECONDS=0

DEFCONFIG="vendor/fog-perf_defconfig"
CORES=$(nproc --all)

TC_DIR="$(pwd)/tc/gcc-aarch64"
OUT_DIR="$(pwd)/out"
# -------------------
echo "[*] Updating system & installing dependencies..."
sudo apt-get update -y && sudo apt-get install -y \
    bc build-essential flex bison lld llvm libssl-dev libelf-dev \
    ccache libncurses-dev libncurses5

if [ ! -d "$TC_DIR" ]; then
    echo "[*] Toolchain not found! Downloading GCC aarch64..."
    mkdir -p "$TC_DIR"

    curl -Ls https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf.tar.xz | tar -xJ --strip-components=1 -C "$TC_DIR"
fi

export PATH="$TC_DIR/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-none-elf-
export KBUILD_BUILD_USER="Filia Lunae🌙"

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
fi

echo "[*] Starting compilation (-j$CORES) with GCC..."

make -j$CORES \
     O="$OUT_DIR" \
     Image.gz 2>&1 | tee "$OUT_DIR/build.log"

KERNEL_IMAGE="$OUT_DIR/arch/arm64/boot/Image.gz"

if [[ -f "$KERNEL_IMAGE" ]]; then
    echo "====================================="
    echo "   COLUMBINA KERNMOON SUCCESS"
    echo "   Time: $((SECONDS/60))m $((SECONDS%60))s"
    echo "   Output: $KERNEL_IMAGE"
    echo "====================================="
else
    echo "!!! Compilation failed. Check $OUT_DIR/build.log"
    exit 1
fi