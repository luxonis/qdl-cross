#!/bin/bash
set -e 

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
    cp ./libusb/.libs/libusb-1.0.so.0 $OUT_DIR
    popd
}

function build_qdl {
    pushd qdl
    # git apply ../patches/qdl_dont_use_pkg-config.patch
    make -j8 CFLAGS="-I ../libxml2/include/ -I ../libusb/libusb/" LDFLAGS="-Wl,-Bdynamic -L../libusb/libusb/.libs/ -lusb-1.0 -Wl,-Bstatic ../libxml2/.libs/libxml2.a -lm -lc -static-libgcc"
    cp ./qdl ${OUT_DIR}
    popd
}

build_libxml
build_libusb
build_qdl

cp ./qdl.sh ${OUT_DIR}

# Make tar package
pushd ${OUT_DIR}
chmod a+rwx ./*
cd ..
tar czf qdl.tar.gz ./qdl/
chmod a+rwx ./qdl.tar.gz
