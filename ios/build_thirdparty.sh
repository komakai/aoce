#!/bin/sh
# 下载MoltenVK(iOS)并编译ncnn(iOS,vulkan),输出到thirdparty/moltenvk/ios与thirdparty/ncnn/ios
# ncnn使用NCNN_SIMPLEVK=OFF(同android),直接链接MoltenVK,与aoce_vulkan共用vulkan头文件和库
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
MOLTENVK_VERSION=v1.4.2
NCNN_VERSION=20260113
WORK="$ROOT/thirdparty/_dl"
MVK_OUT="$ROOT/thirdparty/moltenvk/ios"
NCNN_OUT="$ROOT/thirdparty/ncnn/ios"

mkdir -p "$WORK/moltenvk" "$WORK/ncnn"

if [ ! -f "$MVK_OUT/lib/libMoltenVK.a" ]; then
    curl -L -o "$WORK/moltenvk/MoltenVK-ios.tar" \
        "https://github.com/KhronosGroup/MoltenVK/releases/download/$MOLTENVK_VERSION/MoltenVK-ios.tar"
    mkdir -p "$WORK/moltenvk/x"
    tar -xf "$WORK/moltenvk/MoltenVK-ios.tar" -C "$WORK/moltenvk/x"
    mkdir -p "$MVK_OUT/lib" "$MVK_OUT/include"
    cp -R "$WORK/moltenvk/x/MoltenVK/MoltenVK/include/" "$MVK_OUT/include/"
    cp "$WORK/moltenvk/x/MoltenVK/MoltenVK/static/MoltenVK.xcframework/ios-arm64/libMoltenVK.a" "$MVK_OUT/lib/"
fi

if [ ! -f "$NCNN_OUT/lib/libncnn.a" ]; then
    curl -L -o "$WORK/ncnn/ncnn-src.zip" \
        "https://github.com/Tencent/ncnn/releases/download/$NCNN_VERSION/ncnn-$NCNN_VERSION-full-source.zip"
    rm -rf "$WORK/ncnn/src"
    mkdir -p "$WORK/ncnn/src"
    unzip -q "$WORK/ncnn/ncnn-src.zip" -d "$WORK/ncnn/src"
    cmake -S "$WORK/ncnn/src" -B "$WORK/ncnn/src/build-ios" \
        -DCMAKE_TOOLCHAIN_FILE="$WORK/ncnn/src/toolchains/ios.toolchain.cmake" \
        -DPLATFORM=OS64 -DARCHS=arm64 -DDEPLOYMENT_TARGET=15.0 \
        -DENABLE_BITCODE=OFF -DENABLE_ARC=OFF -DENABLE_VISIBILITY=OFF \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$NCNN_OUT" \
        -DNCNN_VULKAN=ON -DNCNN_SIMPLEVK=OFF -DNCNN_OPENMP=OFF -DNCNN_SHARED_LIB=OFF \
        -DNCNN_BUILD_EXAMPLES=OFF -DNCNN_BUILD_TOOLS=OFF -DNCNN_BUILD_BENCHMARK=OFF -DNCNN_BUILD_TESTS=OFF \
        -DVulkan_INCLUDE_DIR="$MVK_OUT/include" -DVulkan_LIBRARY="$MVK_OUT/lib/libMoltenVK.a"
    cmake --build "$WORK/ncnn/src/build-ios" -j 8
    cmake --install "$WORK/ncnn/src/build-ios"
fi

echo "MoltenVK: $MVK_OUT"
echo "ncnn:     $NCNN_OUT"
