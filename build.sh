#! /bin/bash

set -exo pipefail

if [[ "$VERSION" == "" ]] || [[ "$URL" == "" ]]; then
    export VERSION=21.02
    export URL=https://sourceforge.net/projects/sevenzip/files/7-Zip/21.02/7z2102-src.7z/download

    echo "\$VERSION and/or \$URL not set, using defaults: $VERSION $URL"
fi

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

if type wget &>/dev/null; then
    wget "$URL" -O src.7z
elif type curl &>/dev/null; then
    curl "$URL" -o src.7z
else
    echo "error: need either curl or wget to download the source code"
    exit 1
fi

7za x src.7z

if [[ "$CI" != "" ]]; then
    procs="$(nproc --ignore=1)"
else
    procs="$(nproc)"
fi

# default makefile, does not build assembler code
makefile="../../cmpl_gcc.mak"

# we can optionally build with the assembler if requested by the user
if [[ "$BUILD_ASM" != "" ]]; then
    mkdir asmc
    wget https://github.com/nidud/asmc/archive/refs/heads/master.tar.gz -O - | tar xz -C asmc --strip-components=1
    export PATH="$(readlink -f asmc/source/asmc/linux/bin):$PATH"
    chmod +x asmc/source/asmc/linux/bin/asmc

    makefile="../../cmpl_gcc_x64.mak"
fi

pushd CPP/7zip/UI/Console

    # patch to build fully statically (optional)
    if [[ "$STATIC_BUILD" != "" ]]; then
        sed -i 's|^LDFLAGS_STATIC\s*=\.*|& -static -static-libstdc++ -static-libgcc|g' ../../7zip_gcc.mak
    fi

    make -f "$makefile" -j "$procs"

    cp b/g*/7z "$OLD_CWD"

popd

# the regular binary has a dependency on some 7z.so
# there is some "Alone2" bundle which builds a 7zz binary that does not have such a dependency, therefore we also build this

pushd CPP/7zip/Bundles/Alone2

    make -f "$makefile" -j "$procs"

    cp b/g*/7zz "$OLD_CWD"

popd
