#!/bin/bash
set -e
SECONDS=0

# ===== BASIC CONFIG =====
DEFCONFIG="vendor/fog-perf_defconfig"
OUT_DIR="$(pwd)/out"

# ===== ARCH =====
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# ===== BUILD INFO =====
export KBUILD_BUILD_USER="Rin"
export KBUILD_BUILD_HOST="Anomaly-arc"

# ===== CORE HANDLING =====
if [[ -n "$GITHUB_ACTIONS" ]]; then
    CORES=$(nproc)
    echo "[*] GitHub Actions detected, using $CORES cores"
else
    CORES=4
    echo "[*] Local build, using $CORES cores"
fi

# ===== CLEAN =====
if [[ "$1" == "-c" || "$1" == "--clean" ]]; then
    echo "[*] Cleaning kernel output"
    rm -rf "$OUT_DIR"
    make mrproper
    exit 0
fi

# ===== PREPARE =====
mkdir -p "$OUT_DIR"

if [[ ! -f "$OUT_DIR/.config" ]]; then
    echo "[*] Generating defconfig: $DEFCONFIG"
    make O="$OUT_DIR" $DEFCONFIG
    make O="$OUT_DIR" olddefconfig
fi

# ===== BUILD =====
echo "[*] Starting compilation (-j$CORES)..."
make -j"$CORES" \
     O="$OUT_DIR" \
     Image.gz

# ===== RESULT =====
KERNEL_IMAGE="$OUT_DIR/arch/arm64/boot/Image.gz"

if [[ -f "$KERNEL_IMAGE" ]]; then
    echo "====================================="
    echo "COMPILE SUCCESSFUL"
    echo "Time: $((SECONDS/60))m $((SECONDS%60))s"
    echo "Output: $KERNEL_IMAGE"
    echo "====================================="
else
    echo "Compilation failed."
    exit 1
fi
