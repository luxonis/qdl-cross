#!/bin/bash
set -e 

git submodule update --init --recursive

SCRIPT_DIR=$(dirname $(realpath "$0"))
OUT_DIR=${SCRIPT_DIR}/.out/qdl/
mkdir -p $OUT_DIR

function build_libxml {
    pushd libxml2
    ./autogen.sh
    make -j8 LDFLAGS=-static
    popd
}

function build_libusb {
    pushd libusb
    ./autogen.sh --disable-udev
    make -j8 LDFLAGS=-static
    popd
}

function build_qdl {
    pushd qdl
    # Libusb (LGPL) can be statically linked for simplicity since https://github.com/luxonis/qdl-cross is provided.
    # https://www.gnu.org/licenses/gpl-faq.html#GPLIncompatibleLibs
    make -j8 CFLAGS='-I ../libxml2/include/ -I ../libusb/libusb/' LDFLAGS='-static ../libusb/libusb/.libs/libusb-1.0.a ../libxml2/.libs/libxml2.a -lm -lc'
    cp ./qdl ${OUT_DIR}
    popd
}

build_libxml
build_libusb
build_qdl
