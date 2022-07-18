#!/bin/sh -l

echo "Hello $1"
time=$(date)
echo "$HOME"
echo "::set-output name=time::$time"
ls "$GITHUB_WORKSPACE"
