#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

build_deb_for_dist() {
    dist=$1
    arch=$2
    version=$3

    echo ""
    echo "=========================================================================="
    echo " build-deb.sh (${dist}:${arch}:${version})"
    echo "=========================================================================="
    echo ""

    cd release

    mkdir -pv source/${dist}

    cd ..
    cd ..

    dpkg-source --build ukuu

    mv -vf ukuu_${version}.dsc ukuu/release/source/${dist}
    mv -vf ukuu_${version}.tar.xz ukuu/release/source/${dist}

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failure, again!"; exit 1; fi

    echo "--------------------------------------------------------------------------"

    cd ukuu

    ls -l release/source/${dist}

    mkdir -pv release/${dist}/${arch}

    echo "-------------------------------------------------------------------------"

    sudo -S pbuilder --build --distribution ${dist} --architecture ${arch} --basetgz /var/cache/pbuilder/${dist}-${arch}-base.tgz release/source/${dist}/ukuu_${version}.dsc

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failure, again!"; exit 1; fi

    echo "--------------------------------------------------------------------------"

    sudo cp -pv /var/cache/pbuilder/result/ukuu_${version}_${arch}.deb release/${dist}/${arch}
    sudo cp -pv /var/cache/pbuilder/result/ukuu_${version}_${arch}.changes release/${dist}/${arch}

    if [ "${dist}" != "xenial" ]; then
        sudo cp -pv /var/cache/pbuilder/result/ukuu_${version}_${arch}.buildinfo release/${dist}/${arch}
        sudo cp -pv /var/cache/pbuilder/result/ukuu-dbgsym_${version}_${arch}.ddeb release/${dist}/${arch}
    fi

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failure, again!"; exit 1; fi

    echo "--------------------------------------------------------------------------"

    sudo rm -r /var/cache/pbuilder/result/*
}

mkdir release

build_deb_for_dist xenial i386 18.10
build_deb_for_dist xenial amd64 18.10

build_deb_for_dist bionic i386 18.10
build_deb_for_dist bionic amd64 18.10

build_deb_for_dist disco i386 18.10
build_deb_for_dist disco amd64 18.10

#build_deb_for_dist eoan i386 18.10
#build_deb_for_dist eoan amd64 18.10

cd "$backup"

