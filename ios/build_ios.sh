#!/bin/sh
# 生成iOS的Xcode工程: ios/build/aoce.xcodeproj
# 用法: ios/build_ios.sh <Apple开发者Team ID> [bundle id前缀,默认aoce.samples]
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TEAM_ID=${1:-}
BUNDLE_PREFIX=${2:-aoce.samples}

if [ -z "$TEAM_ID" ]; then
    echo "usage: $0 <team id> [bundle id prefix]"
    echo "team id: Xcode > Settings > Accounts, or the OU field of your 'Apple Development' certificate"
    exit 1
fi

for dep in "$ROOT/thirdparty/moltenvk/ios/lib/libMoltenVK.a" "$ROOT/thirdparty/ncnn/ios/lib/libncnn.a"; do
    if [ ! -f "$dep" ]; then
        echo "missing $dep, see ios/README.md"
        exit 1
    fi
done

cmake -S "$ROOT" -B "$ROOT/ios/build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DAOCE_IOS_TEAM_ID="$TEAM_ID" \
    -DAOCE_IOS_BUNDLE_PREFIX="$BUNDLE_PREFIX"

echo "open $ROOT/ios/build/aoce.xcodeproj and run the aoceswigtest or aocencnntest scheme"
