#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

#../BUILD_CONFIG

echo ""
echo "=========================================================================="
echo " build-source.sh"
echo "=========================================================================="
echo ""

echo "app_name: $app_name"
echo "pkg_name: $pkg_name"
echo "--------------------------------------------------------------------------"

# clean build dir

rm -rfv /tmp/builds
mkdir -pv /tmp/builds

#ninja clean

mkdir -pv ../release/source

echo "--------------------------------------------------------------------------"

cd ..
cd ..

# build source package
dpkg-source --build ukuu

mv -vf $pkg_name*.dsc ukuu/release/source/
mv -vf $pkg_name*.tar.xz ukuu/release/source/

if [ $? -ne 0 ]; then cd "$backup"; echo "Failed"; exit 1; fi

echo "--------------------------------------------------------------------------"

# list files
ls -l ukuu/release/source

echo "-------------------------------------------------------------------------"

cd "$backup"

