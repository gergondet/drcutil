#!/usr/bin/env bash

DRCUTIL=$PWD

source config.sh
source packsrc.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR
built_dirs=

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PATH=$PREFIX/bin:$PATH

if [ "$ENABLE_ASAN" -eq 1 ]; then
    BUILD_TYPE=RelWithDebInfo
    ASAN_OPTIONS=(-DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-O2 -g -DNDEBUG -fsanitize=address" -DCMAKE_C_FLAGS_RELWITHDEBINFO="-O2 -g -DNDEBUG -fsanitize=address")
else
    ASAN_OPTIONS=()
fi

cmake_install_with_option() {
    SUBDIR="$1"
    shift

    if [ ! -d "$SRC_DIR/$SUBDIR" ]; then
	return
    fi

    # check existence of the build directory
    if [ ! -d "$SRC_DIR/$SUBDIR/build" ]; then
        mkdir "$SRC_DIR/$SUBDIR/build"
    fi
    cd "$SRC_DIR/$SUBDIR/build"

    COMMON_OPTIONS=(-DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "${ASAN_OPTIONS[@]}")
    echo cmake $(printf "'%s' " "${COMMON_OPTIONS[@]}" "$@") .. | tee config.log

    cmake "${COMMON_OPTIONS[@]}" "$@" .. 2>&1 | tee -a config.log

    $SUDO make -j$MAKE_THREADS_NUMBER install 2>&1 | tee $SRC_DIR/$SUBDIR.log

    built_dirs="$built_dirs $SUBDIR"
}

cd $SRC_DIR/OpenRTM-aist
if [ ! -e configure ]; then
    ./build/autogen
fi
if [ $BUILD_TYPE != "Release" ]; then
    EXTRA_OPTION=(--enable-debug)
else
    EXTRA_OPTION=()
fi
./configure --prefix="$PREFIX" --without-doxygen "${EXTRA_OPTION[@]}"

built_dirs="$built_dirs OpenRTM-aist"

if [ "$ENABLE_ASAN" -eq 1 ]; then
    # We set -fsanitize=address here, after configure, because this
    # flag interferes with detecting the flags needed for pthreads,
    # causing problems later on.
    EXTRA_OPTION=(CXXFLAGS="-O2 -g3 -fsanitize=address" CFLAGS="-O2 -g3 -fsanitize=address")
    # Report, but don't fail on, leaks in program samples during build.
    export LSAN_OPTIONS="exitcode=0"
else
    EXTRA_OPTION=()
fi
$SUDO make -j$MAKE_THREADS_NUMBER install "${EXTRA_OPTION[@]}" \
   | tee $SRC_DIR/OpenRTM-aist.log

cmake_install_with_option "openhrp3" -DCOMPILE_JAVA_STUFF=OFF -DBUILD_GOOGLE_TEST="$BUILD_GOOGLE_TEST" -DOPENRTM_DIR="$PREFIX"

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ "$UBUNTU_VER" != "16.04" ]; then
	cmake_install_with_option "octomap-$OCTOMAP_VERSION"
    fi
    EXTRA_OPTION=()
else
    EXTRA_OPTION=(-DINSTALL_HRPIO=OFF)
fi
cmake_install_with_option hrpsys-base -DCOMPILE_JAVA_STUFF=OFF -DBUILD_KALMAN_FILTER=OFF -DBUILD_STABILIZER=OFF -DENABLE_DOXYGEN=OFF "${EXTRA_OPTION[@]}"
cmake_install_with_option HRP4
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    EXTRA_OPTION=()
else
    EXTRA_OPTION=(-DGENERATE_FILES_FOR_SIMULATION=OFF)
fi
cmake_install_with_option sch-core
cmake_install_with_option hmc2 -DCOMPILE_JAVA_STUFF=OFF "${EXTRA_OPTION[@]}"
cmake_install_with_option hrpsys-humanoid -DCOMPILE_JAVA_STUFF=OFF -DENABLE_SAVEDBG=$ENABLE_SAVEDBG "${EXTRA_OPTION[@]}"
cmake_install_with_option hrpsys-private
cmake_install_with_option state-observation -DCMAKE_INSTALL_LIBDIR=lib
cmake_install_with_option hrpsys-state-observation
if [ "$ENABLE_SAVEDBG" -eq 1 ]; then
    cmake_install_with_option savedbg -DSAVEDBG_FRONTEND_NAME=savedbg-hrp -DSAVEDBG_FRONTEND_ARGS="-P 'dpkg -l > dpkg' -f '$PREFIX/share/robot-sources.tar.bz2'"
fi

packsrc $built_dirs
$SUDO cp robot-sources.tar.bz2 $PREFIX/share/

echo "add the following line to your .bashrc"
echo "source $DRCUTIL/setup.bash"
echo "export PATH=$PREFIX/bin:\$PATH" > $DRCUTIL/setup.bash
echo "export LD_LIBRARY_PATH=$PREFIX/lib:$PREFIX/share/DynamoRIO-$DYNAMORIO_VERSION/ext/lib$ARCH_BITS/release:\$LD_LIBRARY_PATH" >> $DRCUTIL/setup.bash
echo "export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig" >> $DRCUTIL/setup.bash
echo "export PYTHONPATH=$PREFIX/lib/python2.7/dist-packages/hrpsys:\$PYTHONPATH" >> $DRCUTIL/setup.bash
