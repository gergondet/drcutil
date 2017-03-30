#!/usr/bin/env bash

source config.sh
source packsrc.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR

export LSAN_OPTIONS="exitcode=0"

cd $SRC_DIR

cd OpenRTM-aist
echo -n "building OpenRTM-aist ... "
$SUDO make -j$MAKE_THREADS_NUMBER install > $SRC_DIR/OpenRTM-aist.log 2>&1
if [ "$?" -eq 0 ]
then
    echo "success"
else
    echo -e "\e[31mfail\e[m"
fi
cd ../

build_install() {
    for dir_name in $@; do
	if [ -e $dir_name ]; then
            cd "$dir_name/build"
	    echo -n "building $dir_name ... "
	    if [ "${VERBOSE-0}" -eq 0 ]; then
		$SUDO make -j$MAKE_THREADS_NUMBER install > $SRC_DIR/${dir_name}.log 2>&1
	    else
		$SUDO make -j$MAKE_THREADS_NUMBER install 2>&1 | tee $SRC_DIR/${dir_name}.log
	    fi
	    if [ "$?" -eq 0 ]
	    then
		echo "success"
                built_dirs="$built_dirs $dir_name"
	    else
		echo -e "\e[31mfail\e[m"
	    fi
            cd ../../
	fi
    done
}

built_dirs=
build_install "openhrp3" "hrpsys-base" "HRP4" "sch-core" "hmc2" "hrpsys-private" "hrpsys-humanoid" "state-observation" "hrpsys-state-observation" "savedbg"

packsrc $built_dirs
$SUDO mv robot-sources.tar.bz2 $PREFIX/share/
