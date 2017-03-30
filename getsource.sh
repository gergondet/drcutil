#!/usr/bin/env bash

source config.sh

sudo apt-get -y install git subversion

get_source() {
    if [ ! -e $2 ]; then
	$1 $2
    fi
}

if [ ! -e $SRC_DIR ]; then
  mkdir -p $SRC_DIR 
fi

cd $SRC_DIR

get_source "svn co http://svn.openrtm.org/OpenRTM-aist/branches/RELENG_1_1/OpenRTM-aist" OpenRTM-aist
get_source "git clone https://github.com/fkanehiro/openhrp3.git" openhrp3
get_source "git clone -b topic/JRL git@gite.lirmm.fr:hrp4-confidential/hrp4-system" HRP4
get_source "git clone ssh://$ATOM_USER_NAME@atom.a01.aist.go.jp/git/hrpsys-private" hrpsys-private
get_source "git clone --recursive ssh://$ATOM_USER_NAME@atom.a01.aist.go.jp/usr/users/benallegue/git/hrpsys-state-observation" hrpsys-state-observation

get_source "git clone https://github.com/fkanehiro/hrpsys-base" hrpsys-base
get_source "git clone --recursive https://github.com/mehdi-benallegue/state-observation" state-observation
get_source "git clone https://github.com/jrl-umi3218/hmc2" hmc2
get_source "git clone https://github.com/jrl-umi3218/hrpsys-humanoid" hrpsys-humanoid
get_source "git clone --recursive https://github.com/mehdi-benallegue/sch-core" sch-core
if [ "$ENABLE_SAVEDBG" -eq 1 ]; then
    get_source "git clone https://bitbucket.org/jun0/savedbg" savedbg
fi
