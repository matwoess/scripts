#!/usr/bin/env bash

# 0. Install ADB with `yay -S android-tools`
# 1. Turn on USB-Debugging on TV
# 2. Issue connect command (works wirelessly)
# 3. Check with `adb devices`
# 4. Put setting

if [[ $# -lt 1 ]] ; then
    echo "$(basename "$0"): must specify the TV's IP address as argument"
    exit 1
fi


TV_IP=$1 # Replace with actual TV IP
adb connect $TV_IP # port optional
adb devices # for info
adb shell settings put system sound_effects_enabled 0
