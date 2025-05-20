#!/bin/bash
set -e

git submodule update --init --recursive

SCRIPT_DIR=$(dirname $(realpath "$0"))
OUT_DIR=${SCRIPT_DIR}/.out/qdl/
mkdir -p $OUT_DIR

if [[ "$OSTYPE" == "darwin"* ]]; then
    is_macos=true
else
    is_macos=false
fi

function build_libxml {
    pushd libxml2
    ./autogen.sh
    if $is_macos; then
        make -j8
    else
        make -j8 LDFLAGS=-static
    fi
    popd
}

function build_libusb {
    pushd libusb
    ./autogen.sh --disable-udev
    if $is_macos; then
        make -j8
    else
        make -j8 LDFLAGS=-static
    fi
    popd
}

function build_qdl_linux {
    pushd qdl
    # Libusb (LGPL) can be statically linked for simplicity since https://github.com/luxonis/qdl-cross is provided.
    # https://www.gnu.org/licenses/gpl-faq.html#GPLIncompatibleLibs
    make -j8 CFLAGS='-I ../libxml2/include/ -I ../libusb/libusb/' LDFLAGS='-static ../libusb/libusb/.libs/libusb-1.0.a ../libxml2/.libs/libxml2.a -lm -lc'
    cp ./qdl ${OUT_DIR}
    popd
}

function build_qdl_macos {
    pushd qdl
    make -j8 CFLAGS='-I ../libxml2/include/ -I ../libusb/libusb/' LDFLAGS='-L ../libusb/libusb/.libs/ -lusb-1.0 -L ../libxml2/.libs/ -lxml2 -lm -lc'
    dst_lib_dir=${OUT_DIR}/lib/
    dst_bin_dir=${OUT_DIR}/bin/
    mkdir -p ${dst_bin_dir}
    mkdir -p ${dst_lib_dir}
    cp ../libxml2/.libs/libxml2.16.dylib ${dst_lib_dir}
    cp ../libusb/libusb/.libs/libusb-1.0.0.dylib ${dst_lib_dir}
    cp ./qdl ${dst_bin_dir}
    # Note that to make the QDL work, you need to control the location of the dylibs (or add them to a standard search dir). You can modify the rpath in the binary.
    # for example: install_name_tool -add_rpath "/usr/local/lib/oakctl/" ./qdl
}

build_libxml
build_libusb
if $is_macos; then
    build_qdl_macos
else
    build_qdl_linux
fi
