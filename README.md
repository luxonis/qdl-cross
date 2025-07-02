# [QDL](https://github.com/linux-msm/qdl) cross

This repository provides build scripts to build:  
* A fully static qdl for `linux (x86_64 and aarch64)`.  
* A standalone package with qdl and all it's dependencies for `macOS (x86_64/aarch64)`.  
* A standalone package with qdl and all it's dependencies for `windows (x86_64)`.

## Prebuilds

There are ci generated prebuilds available on the [release page](https://github.com/luxonis/qdl-cross/releases/tag/latest)!

## Build it yourself

If you want to build qdl yourself, you can run the `./build-qdl.sh` script.  
You can take a look at the [main.yml file](https://github.com/luxonis/qdl-cross/blob/main/.github/workflows/main.yml) to see detailed commands and the build environment used.

The binary for linux is statically linked with the musl stdlib for max portability (and therefore compiled within an `alpine` linux container, since it comes with static musl pre-installed).

## Pre-requisites:

Install the following via your package manager:

```sh
bash git make pkg-config gcc musl-dev autoconf libtool automake linux-headers
```
