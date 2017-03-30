#!/usr/bin/env bash

source config.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR

#OpenRTM-aist
sudo apt-get -y install autoconf
if [ "$UBUNTU_VER" = "16.04" ]; then
    sudo apt-get -y install libtool-bin
else
    sudo apt-get -y install libtool
fi

#openhrp3
cd $SRC_DIR/openhrp3/util
./installPackages.sh packages.list.ubuntu.$UBUNTU_VER

sudo sed -i -e 's/giopMaxMsgSize = 2097152/giopMaxMsgSize = 2147483648/g' /etc/omniORB.cfg

if [ "$BUILD_GOOGLE_TEST" = "ON" ]; then
    sudo apt-get -y install libgtest-dev
fi

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ "$UBUNTU_VER" = "16.04" ]; then
	sudo apt-get -y install libpcl-dev libproj-dev
	sudo apt-get -y install liboctomap-dev
    else
	sudo add-apt-repository -y ppa:v-launchpad-jochen-sprickerhof-de/pcl
	sudo apt-get update || true #ignore checksum error
	sudo apt-get -y install libpcl-all
    fi
fi
#hrpsys-base
sudo apt-get -y install libxml2-dev libsdl-dev libglew-dev libopencv-dev libcvaux-dev libhighgui-dev libqhull-dev freeglut3-dev libxmu-dev python-dev libboost-python-dev ipython openrtm-aist-python
#hmc2
sudo apt-get -y install libyaml-dev libncurses5-dev

if [ "$ENABLE_SAVEDBG" -eq 1 ]; then
    if [ "$UBUNTU_VER" = 14.04 ]; then
        REALPATH=realpath
    else
        REALPATH=
    fi
    sudo apt-get -y install elfutils $REALPATH
fi

# Eigen 3.2.10
cd $WORKSPACE
sudo rm -fr 3.2.10.tar.gz eigen-eigen-b9cd8366d4e8
wget -q http://bitbucket.org/eigen/eigen/get/3.2.10.tar.gz
tar zxvf 3.2.10.tar.gz
cd eigen-eigen-b9cd8366d4e8
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
sudo make -j$MAKE_THREADS_NUMBER install
cd ../..
sudo rm -fr 3.2.10.tar.gz eigen-eigen-b9cd8366d4e8

wget -q http://sourceforge.net/projects/collada-dom/files/Collada%20DOM/Collada%20DOM%202.4/collada-dom-2.4.0.tgz
tar zxvf collada-dom-2.4.0.tgz
cd collada-dom-2.4.0
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
sudo make -j$MAKE_THREADS_NUMBER install
cd ../..
sudo rm -fr collada-dom-2.4.0.tgz collada-dom-2.4.0
