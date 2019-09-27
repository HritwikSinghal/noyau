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
    echo " build-deb.sh ($dist:$arch:$version)"
    echo "=========================================================================="
    echo ""

    #rm -rfv /tmp/builds
    #mkdir -pv /tmp/builds

    echo $PWD

    #cd ..

    #echo $PWD

    cd release

    mkdir -pv source

    cd ..
    cd ..

    dpkg-source --build ukuu

    mv -vf ukuu_${version}.dsc ukuu/release/source
    mv -vf ukuu_${version}.tar.xz ukuu/release/source

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failed"; exit 1; fi

    echo "--------------------------------------------------------------------------"

    cd ukuu

    ls -l release/source

    mkdir -pv release/${arch}

    echo "-------------------------------------------------------------------------"

    sudo -S pbuilder --build --distribution $dist --architecture $arch --basetgz /var/cache/pbuilder/${dist}-${arch}-base.tgz release/source/ukuu_${version}.dsc

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failed"; exit 1; fi

    echo "--------------------------------------------------------------------------"

    sudo cp -pv --no-preserve=ownership /var/cache/pbuilder/result/ukuu_${version}_${arch}.deb release/${arch}

    if [ $? -ne 0 ]; then cd "$backup"; echo "Failed"; exit 1; fi

    echo "--------------------------------------------------------------------------"
}

#build_deb_for_dist xenial i386 18.10
#build_deb_for_dist xenial amd64 18.10

#build_deb_for_dist bionic i386 18.10
#build_deb_for_dist bionic amd64 18.10

build_deb_for_dist disco i386 18.10
build_deb_for_dist disco amd64 18.10

#build_deb_for_dist eoan i386 18.10
#build_deb_for_dist eoan amd64 18.10

cd "$backup"

