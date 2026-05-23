#!/bin/bash
set -e
SECONDS=0
export TMPDIR=/tmp
mkdir -p /tmp
chmod 1777 /tmp

# CONFIG
DEFCONFIG="vendor/fog-perf_defconfig"
CORES=${CORES:-7}
OUT_DIR="$(pwd)/out"

# ENVIRONMENT
export ARCH=arm64
export SUBARCH=arm64


# DETECT CROSS COMPILER
if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    CROSS_COMPILE="aarch64-linux-gnu-"
elif command -v aarch64-linux-android-gcc >/dev/null 2>&1; then
    CROSS_COMPILE="aarch64-linux-android-"
else
    echo "[!] No cross compiler found!"
    exit 1
fi

echo "[*] Detected CROSS_COMPILE: $CROSS_COMPILE"

# TOOL CHECK
echo "[*] Checking toolchain..."

command -v ${CROSS_COMPILE}gcc >/dev/null || {
    echo "[!] Missing cross gcc"
    exit 1
}

for tool in ar nm objcopy objdump strip; do
    command -v $tool >/dev/null || {
        echo "[!] Missing system tool: $tool"
        exit 1
    }
done

# EXPORT BUILD ENV
export CROSS_COMPILE
unset LD

if command -v ccache >/dev/null 2>&1; then
    CC="ccache ${CROSS_COMPILE}gcc"
    echo "[*] CCache detected and enabled!"
else
    CC="${CROSS_COMPILE}gcc"
    echo "[!] CCache not found, using plain GCC."
fi

# force native binutils
export AR=ar
export NM=nm
export OBJCOPY=objcopy
export OBJDUMP=objdump
export STRIP=strip

# kernel-safe build flags (IMPORTANT FIX FOR YOUR ERROR)
export KCFLAGS="-fno-pie"
export KBUILD_CFLAGS="-fno-pie"
export KBUILD_LDFLAGS=""

# override internal kernel tools
export KBUILD_AR=ar
export KBUILD_NM=nm
export KBUILD_OBJDUMP=objdump
export HOSTCC=gcc
export HOSTCXX=g++
export KBUILD_BUILD_USER="Filia-Lunae"
export KBUILD_BUILD_HOST="Arch-Linux ARM-aarch64_Qualcomm-Technologies,_Inc.-FOG-KHAJE-IDP-nopmi"
mkdir -p "$OUT_DIR"
mkdir -p /tmp


# DEFCONFIG
if [[ ! -f "$OUT_DIR/.config" ]]; then
    echo "[*] Generating defconfig: $DEFCONFIG"
    make O="$OUT_DIR" $DEFCONFIG
    make O="$OUT_DIR" olddefconfig
fi

# BUILD START
echo "[*] Starting compilation (-j$CORES)..."

make -j"$CORES" O="$OUT_DIR" \
    CROSS_COMPILE=$CROSS_COMPILE \
    CC="$CC" \
    AR=ar \
    NM=nm \
    OBJCOPY=objcopy \
    OBJDUMP=objdump \
    STRIP=strip \
    KCFLAGS="-fno-pie" \
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
    echo "====================================="
else
    echo "❌ Compilation failed."
    exit 1
fi