#!/usr/bin/env bash

# 1. Turn on USB-Debugging on TV
# 2. Issue connect command (works wirelessly)
# 3. Check with `adb devices`
# 4. Put setting

TV_IP=$1 # Replace with actual TV IP
adb connect $TV_IP # port optional
adb shell settings put system sound_effects_enabled 0
