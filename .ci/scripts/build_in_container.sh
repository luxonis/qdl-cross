#!/bin/bash
set -e

./.ci/scripts/install_dependencies_alpine.sh
git config --global --add safe.directory /__w/qdl-cross/qdl-cross
./build-qdl.sh
