#! /bin/bash

set -exo pipefail

docker build --pull -t static-7zip-build .

docker run \
--rm -i -v "$(readlink -f "$(dirname "$0")")":/ws -w /ws --user "$(id -u)" \
-e CI=1 -e VERSION -e URL -e STATIC_BUILD -e BUILD_ASM \
static-7zip-build \
bash <<\EOF
    source /opt/rh/devtoolset-*/enable
    bash build.sh
EOF
