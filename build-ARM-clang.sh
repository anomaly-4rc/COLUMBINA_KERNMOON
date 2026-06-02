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

# TOOL CHECK (CLANG & LLVM)
echo "[*] Checking LLVM toolchain..."

for tool in clang ld.lld llvm-ar llvm-nm llvm-objcopy llvm-objdump llvm-strip; do
    command -v $tool >/dev/null || {
        echo "[!] Missing LLVM tool: $tool"
        exit 1
    }
done

# EXPORT BUILD ENV (SWITCH TO LLVM)
export CLANG_TRIPLE=aarch64-linux-gnu-

# Setup CC with CCache handling
if command -v ccache >/dev/null 2>&1; then
    CC="ccache clang"
    echo "[*] CCache detected and enabled with Clang!"
else
    CC="clang"
    echo "[!] CCache not found, using plain Clang."
fi

# Override internal kernel tools with LLVM Binutils
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip
export LD=ld.lld

# kernel-safe build flags
export KCFLAGS="-fno-pie"
export KBUILD_CFLAGS="-fno-pie"
export KBUILD_LDFLAGS=""

# Override host compiler & targets
export KBUILD_AR=llvm-ar
export KBUILD_NM=llvm-nm
export KBUILD_OBJDUMP=llvm-objdump
export HOSTCC=clang
export HOSTCXX=clang++
export KBUILD_BUILD_USER="Filia-Lunae"
export KBUILD_BUILD_HOST="Arch-ARM64"

mkdir -p "$OUT_DIR"

# DEFCONFIG
if [[ ! -f "$OUT_DIR/.config" ]]; then
    echo "[*] Generating defconfig: $DEFCONFIG"
    make O="$OUT_DIR" CC="$CC" $DEFCONFIG
    make O="$OUT_DIR" CC="$CC" olddefconfig
fi

# BUILD START
echo "[*] Starting Clang compilation (-j$CORES)..."

make -j"$CORES" O="$OUT_DIR" \
    CC="$CC" \
    LD=ld.lld \
    AR=llvm-ar \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    KCFLAGS="-fno-pie" \
    Image.gz dtbs

# RESULT
KERNEL_IMAGE="$OUT_DIR/arch/arm64/boot/Image.gz"
DTB_DIR="$OUT_DIR/arch/arm64/boot/dts/vendor/qcom"

if [[ -f "$KERNEL_IMAGE" ]]; then
    echo "====================================="
    echo "✅ COMPILE SUCCESSFUL (CLANG MODE)"

    echo "[*] Combining DTBs..."
    cat "$DTB_DIR"/*.dtb > "$OUT_DIR/dtb_combined"

    echo "[*] Creating Image.gz-dtb..."
    cat "$KERNEL_IMAGE" "$OUT_DIR/dtb_combined" > "$OUT_DIR/Image.gz-dtb"

    echo "Time: $((SECONDS/60))m $((SECONDS%60))s"
    echo "====================================="
    chmod +x wrapping.sh
    ./wrapping.sh
else
    echo "❌ Compilation failed."
    exit 1
fi
