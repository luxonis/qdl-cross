#!/bin/bash
set -e
set -x

git submodule update --init --recursive

SCRIPT_DIR=$(dirname "$(realpath "$0")")
OUT_DIR_BASE="${SCRIPT_DIR}/.out"
OUT_DIR_QDL="${OUT_DIR_BASE}/qdl"
mkdir -p "${OUT_DIR_QDL}"

# Determine OS
is_macos=0
is_windows=0

if [[ "$OSTYPE" == darwin* ]]; then
    is_macos=1
elif [[ "$OSTYPE" == win32 || "$OSTYPE" == msys || "$OSTYPE" == cygwin ]]; then
    is_windows=1
fi

# Static linking is only for non-Windows and non-macOS
if ((is_windows || is_macos)); then
    compile_static=0
else
    compile_static=1
fi

function build_libxml {
    pushd libxml2
    ./autogen.sh
    if ((compile_static)); then
        make -j8 LDFLAGS=-static
    else
        make -j8
    fi
    popd
}

function build_libusb {
    pushd libusb
    ./autogen.sh --disable-udev
    if ((compile_static)); then
        make -j8 LDFLAGS=-static
    else
        make -j8
    fi
    popd
}

BUILD_QDL_CFLAGS_COMMON='-I ../libxml2/include/ -I ../libusb/libusb/ -O2 -Wall -g'

function build_qdl_linux {
    pushd qdl
    make -j8 CFLAGS="${BUILD_QDL_CFLAGS_COMMON}" LDFLAGS='-static ../libusb/libusb/.libs/libusb-1.0.a ../libxml2/.libs/libxml2.a -lm -lc'
    cp ./qdl "${OUT_DIR_QDL}"
    popd
}

function build_qdl_macos {
    pushd qdl
    make -j8 CFLAGS="${BUILD_QDL_CFLAGS_COMMON}" LDFLAGS='-L ../libusb/libusb/.libs/ -lusb-1.0 -L ../libxml2/.libs/ -lxml2 -lm -lc'
    dst_lib_dir="${OUT_DIR_QDL}/lib/"
    dst_bin_dir="${OUT_DIR_QDL}/"
    mkdir -p "${dst_bin_dir}" "${dst_lib_dir}"
    cp ../libxml2/.libs/libxml2.16.dylib "${dst_lib_dir}"
    cp ../libusb/libusb/.libs/libusb-1.0.0.dylib "${dst_lib_dir}"
    cp ./qdl "${dst_bin_dir}"
    install_name_tool -add_rpath "@executable_path/lib" "${dst_bin_dir}/qdl"
    install_name_tool -change "/usr/local/lib/libxml2.16.dylib" @rpath/libxml2.16.dylib "${dst_bin_dir}/qdl"
    install_name_tool -change ""/usr/local/lib/libusb-1.0.0.dylib" @rpath/libusb-1.0.0.dylib "${dst_bin_dir}/qdl"
    pushd "${OUT_DIR_BASE}"
    ls -lah ./
    tar czf "${OUT_DIR_BASE}/qdl-${PLATFORM}.tar.gz" ./qdl
    popd
    popd
}

function build_qdl_windows {
    pushd qdl
    make -j8 CFLAGS="${BUILD_QDL_CFLAGS_COMMON}" LDFLAGS='-L ../libusb/libusb/.libs/ -lusb-1.0 -L ../libxml2/.libs/ -lxml2'
    # ship everything in the same directory on windows.
    dst_lib_dir="${OUT_DIR_QDL}/"
    dst_bin_dir="${OUT_DIR_QDL}/"
    mkdir -p "${dst_bin_dir}" "${dst_lib_dir}"
    cp ../libxml2/.libs/libxml2-16.dll "${dst_lib_dir}"
    cp ../libusb/libusb/.libs/libusb-1.0.dll "${dst_lib_dir}"
    cp ./qdl "${dst_bin_dir}"
    pushd "${OUT_DIR_BASE}"
    ls -lah ./
    tar czf "${OUT_DIR_BASE}/qdl-${PLATFORM}.tar.gz" ./qdl
    popd
    popd
}

build_libxml
build_libusb

if ((is_macos)); then
    build_qdl_macos
elif ((is_windows)); then
    build_qdl_windows
else
    build_qdl_linux
fi
