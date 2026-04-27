#!/usr/bin/env bash
./script/build_and_run.sh run
sleep 5
# Simulate Option + V (V is key code 9)
osascript -e 'tell application "System Events" to key code 9 using {option down}'
sleep 2
mkdir -p Resources
screencapture -x Resources/screenshot.png
