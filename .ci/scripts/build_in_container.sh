#!/bin/bash
set -e

./.ci/scripts/install_dependencies_alpine.sh
./build-qdl.sh
