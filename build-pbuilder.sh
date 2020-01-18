#!/bin/bash

echo ""
echo "======================================================="
echo "build-pbuilder.sh - begin setup"
echo "======================================================="
echo ""

#sudo pbuilder --create --distribution xenial --architecture i386 --basetgz /var/cache/pbuilder/xenial-i386-base.tgz
#sudo pbuilder --create --distribution xenial --architecture amd64 --basetgz /var/cache/pbuilder/xenial-amd64-base.tgz

sudo pbuilder --create --distribution bionic --architecture i386 --basetgz /var/cache/pbuilder/bionic-i386-base.tgz
sudo pbuilder --create --distribution bionic --architecture amd64 --basetgz /var/cache/pbuilder/bionic-amd64-base.tgz

sudo pbuilder --create --distribution disco --architecture i386 --basetgz /var/cache/pbuilder/disco-i386-base.tgz
sudo pbuilder --create --distribution disco --architecture amd64 --basetgz /var/cache/pbuilder/disco-amd64-base.tgz

sudo pbuilder --create --distribution eoan --architecture i386 --basetgz /var/cache/pbuilder/eoan-i386-base.tgz
sudo pbuilder --create --distribution eoan --architecture amd64 --basetgz /var/cache/pbuilder/eoan-amd64-base.tgz

#sudo pbuilder --create --distribution focal --architecture i386 --basetgz /var/cache/pbuilder/focal-i386-base.tgz
sudo pbuilder --create --distribution focal --architecture amd64 --basetgz /var/cache/pbuilder/focal-amd64-base.tgz

## Based on: https://blog.packagecloud.io/eng/2015/05/18/building-deb-packages-with-pbuilder/
