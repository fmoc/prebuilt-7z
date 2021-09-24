#! /bin/bash

set -exo pipefail

# use RAM disk if possible
if [ "$CI" == "" ] && [ -d /dev/shm ]; then
    TEMP_BASE=/dev/shm
else
    TEMP_BASE=/tmp
fi

BUILD_DIR="$(mktemp -d -p "$TEMP_BASE" static-7zip-build-XXXXXX)"

cleanup () {
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
}

trap cleanup EXIT

# store repo root as variable
REPO_ROOT="$(readlink -f "$(dirname "$(dirname "$0")")")"
OLD_CWD="$(readlink -f .)"

pushd "$BUILD_DIR"

VERSION="${VERSION:-21.02}"
url=https://sourceforge.net/projects/sevenzip/files/7-Zip/"$VERSION"/7z"$(sed 's|\.||' <<<"$VERSION")"-src.7z/download

if type wget &>/dev/null; then
    wget "$url" -O src.7z
elif type curl &>/dev/null; then
    curl "$url" -o src.7z
else
    echo "error: need either curl or wget to download the source code"
    exit 1
fi

7za x src.7z

pushd CPP/7zip/UI/Console

# patch to build fully statically (optional)
if [[ "$STATIC_BUILD" != "" ]]; then
    sed -i 's|^LDFLAGS_STATIC\s*=\.*|& -static -static-libstdc++ -static-libgcc|g' ../../7zip_gcc.mak
fi

# build without assembly, which uses some very exotic assembler called asmc that is not easily available
if [[ "$CI" != "" ]]; then
    procs="$(nproc --ignore=1)"
else
    procs="$(nproc)"
fi

make -f ../../cmpl_gcc.mak -j "$procs"

cp b/g/7z "$OLD_CWD"