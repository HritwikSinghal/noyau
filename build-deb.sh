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

    dpkg-source --build noyau

    mv -vf noyau_${version}.dsc noyau/release/source/${dist}
    mv -vf noyau_${version}.tar.xz noyau/release/source/${dist}

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failure, again!"; exit 1; fi

    echo "--------------------------------------------------------------------------"

    cd noyau

    ls -l release/source/${dist}

    mkdir -pv release/${dist}/${arch}

    echo "-------------------------------------------------------------------------"

    sudo -S pbuilder --build --distribution ${dist} --architecture ${arch} --basetgz /var/cache/pbuilder/${dist}-${arch}-base.tgz release/source/${dist}/noyau_${version}.dsc

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failure, again!"; exit 1; fi

    echo "--------------------------------------------------------------------------"

    sudo cp -pv /var/cache/pbuilder/result/noyau_${version}_${arch}.deb release/${dist}/${arch}
    sudo cp -pv /var/cache/pbuilder/result/noyau_${version}_${arch}.changes release/${dist}/${arch}

    if [ "${dist}" != "xenial" ]; then
        sudo cp -pv /var/cache/pbuilder/result/noyau_${version}_${arch}.buildinfo release/${dist}/${arch}
        sudo cp -pv /var/cache/pbuilder/result/noyau-dbgsym_${version}_${arch}.ddeb release/${dist}/${arch}
    fi

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failure, again!"; exit 1; fi

    echo "--------------------------------------------------------------------------"

    sudo rm -r /var/cache/pbuilder/result/*
}

mkdir release

#build_deb_for_dist xenial i386 18.10  #16.04.x LTS (not supported)
#build_deb_for_dist xenial amd64 18.10 #16.04.x LTS (not supported)

build_deb_for_dist bionic i386 18.10  #18.04.x LTS
build_deb_for_dist bionic amd64 18.10 #18.04.x LTS

build_deb_for_dist disco i386 18.10  #19.04
build_deb_for_dist disco amd64 18.10 #19.04

build_deb_for_dist eoan i386 18.10  #19.10
build_deb_for_dist eoan amd64 18.10 #19.10

#build_deb_for_dist focal i386 18.10 #20.04.x LTS
build_deb_for_dist focal amd64 18.10 #20.04.x LTS

cd "$backup"
