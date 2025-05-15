#!/bin/bash

git submodule update --init --recursive

SCRIPT_DIR=$(dirname $(realpath "$0"))
OUT_DIR=${SCRIPT_DIR}/.out/qdl/
mkdir -p $OUT_DIR

function build_libxml {
    pushd libxml2
    LDFLAGS=-static ./autogen.sh
    make -j8
    popd
}

function build_libusb {
    pushd libusb
    ./autogen.sh --disable-udev
    make -j8
    cp ./libusb/.libs/libusb-1.0.so $OUT_DIR
    popd
}

function build_qdl {
    pushd qdl
    # git apply ../patches/qdl_dont_use_pkg-config.patch
    make -j8 CFLAGS="-I ../libxml2/include/ -I ../libusb/libusb/" LDFLAGS="-Wl,-Bdynamic -L${OUT_DIR} -lusb-1.0 -Wl,-Bstatic ../libxml2/.libs/libxml2.a -lm -lc -static-libgcc"
    popd
}

build_libxml
build_libusb
build_qdl
