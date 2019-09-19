#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

. ./BUILD_CONFIG

build_deb_for_dist() {
    dist=$1
    arch=$2

    echo ""
    echo "=========================================================================="
    echo " build-deb.sh : $dist-$arch"
    echo "=========================================================================="
    echo ""

    cd ..
    cd ..

    mkdir -pv ukuu/release/${arch}

    echo "-------------------------------------------------------------------------"

    pbuilder --build --distribution $dist --architecture $arch --basetgz /home/jdowding/pbuilder/disco-base.tgz ukuu/release/source/ukuu_18.10.dsc

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failed"; exit 1; fi

    echo "--------------------------------------------------------------------------"

    cp -pv --no-preserve=ownership /var/cache/pbuilder/result/ukuu_18.10_${arch}.deb ukuu/release/${arch}/
    #cp -pv --no-preserve=ownership ukuu/release/${arch}/ukuu-18.10-amd64.deb ukuu/release/ukuu-18.10-amd64.deb

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failed"; exit 1; fi

    echo "--------------------------------------------------------------------------"
}

#build_deb_for_dist xenial i386
#build_deb_for_dist xenial amd64

#build_deb_for_dist bionic i386
#build_deb_for_dist bionic amd64

#build_deb_for_dist disco i386
build_deb_for_dist disco amd64

cd "$backup"
