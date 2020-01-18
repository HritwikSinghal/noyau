#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

build_source_for_dist() {
    version=$1

    echo ""
    echo "======================================================="
    echo "build-deb.sh - build source - ${version}"
    echo "======================================================="
    echo ""

    debuild -i -us -uc -S

    cd ..

    mv -vf noyau_${version}.dsc noyau/release
    mv -vf noyau_${version}.tar.xz noyau/release
    mv -vf noyau_${version}_source.build noyau/release
    mv -vf noyau_${version}_source.buildinfo noyau/release
    mv -vf noyau_${version}_source.changes noyau/release

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failure, again!"; exit 1; fi

    echo "--------------------------------------------------------------------------"
}

build_deb_for_dist() {
    dist=$1
    arch=$2
    version=$3

    echo ""
    echo "======================================================="
    echo "build-deb.sh - build deb - ${dist}, ${arch}, ${version}"
    echo "======================================================="
    echo ""

    cd noyau

    ls -l release/${dist}/${arch}

    mkdir -pv release/${dist}/${arch}

    echo "-------------------------------------------------------------------------"

    sudo -S pbuilder --build --distribution ${dist} --architecture ${arch} --basetgz /var/cache/pbuilder/${dist}-${arch}-base.tgz release/noyau_${version}.dsc

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failure, again!"; exit 1; fi

    echo "--------------------------------------------------------------------------"

    sudo cp -pv /var/cache/pbuilder/result/noyau_${version}_${arch}.deb release/${dist}/${arch}
    sudo cp -pv /var/cache/pbuilder/result/noyau_${version}_${arch}.changes release/${dist}/${arch}

    if [ "${dist}" != "xenial" ]; then
        sudo cp -pv /var/cache/pbuilder/result/noyau_${version}_${arch}.buildinfo release/${dist}/${arch}
        sudo cp -pv /var/cache/pbuilder/result/noyau-dbgsym_${version}_${arch}.ddeb release/${dist}/${arch}
    fi

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failure, again!"; exit 1; fi

    sudo rm -r /var/cache/pbuilder/result/*

    echo "--------------------------------------------------------------------------"
}

echo ""
echo "======================================================="
echo "build-deb.sh - begin build"
echo "======================================================="
echo ""

mkdir release
cd release

mkdir -pv ${dist}/${arch}

cd ..

build_source_for_dist 18.10

#build_deb_for_dist xenial i386 18.10  #16.04.x LTS (not supported)
#build_deb_for_dist xenial amd64 18.10 #16.04.x LTS (not supported)

build_deb_for_dist bionic i386 18.10 #18.04.x LTS
build_deb_for_dist bionic amd64 18.10 #18.04.x LTS

build_deb_for_dist disco i386 18.10 #19.04
build_deb_for_dist disco amd64 18.10 #19.04

build_deb_for_dist eoan i386 18.10 #19.10
build_deb_for_dist eoan amd64 18.10 #19.10

#build_deb_for_dist focal i386 18.10 #20.04.x LTS
build_deb_for_dist focal amd64 18.10 #20.04.x LTS

cd "$backup"
