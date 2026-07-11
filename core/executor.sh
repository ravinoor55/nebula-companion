#!/bin/bash

COMMAND_TYPE=$1
TARGET=$2

if [ "$COMMAND_TYPE" = "open_app" ]; then
    open -a "$TARGET"
elif [ "$COMMAND_TYPE" = "calculate" ]; then
    echo "$TARGET" | bc
else
    echo "Unknown command type: $COMMAND_TYPE"
fi
