#!/usr/bin/env bash
set -euo pipefail

DEVECO_ROOT="/Applications/DevEco-Studio.app/Contents"
export DEVECO_SDK_HOME="$DEVECO_ROOT/sdk"
export NODE_HOME="$DEVECO_ROOT/tools/node"

"$DEVECO_ROOT/tools/ohpm/bin/ohpm" install
"$DEVECO_ROOT/tools/hvigor/bin/hvigorw" --mode module -p product=default assembleHap

