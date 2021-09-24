#! /bin/bash

docker build -t static-7zip-build .

#exit
docker run --rm -i -v "$(readlink -f "$(dirname "$0")")":/ws -w /ws --user "$(id -u)" static-7zip-build bash <<\EOF
source /opt/rh/devtoolset-*/enable
bash build.sh
EOF
