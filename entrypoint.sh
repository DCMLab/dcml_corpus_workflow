#!/bin/sh -l

echo "Hello $1"
time=$(date)
echo "$HOME"
echo "::set-output name=time::$time"

pyv_="$(python -V 2>&1)"
echo "$pyv_"

pyv="$(python3 -V 2>&1)"
echo "$pyv"

ls "$GITHUB_WORKSPACE"
