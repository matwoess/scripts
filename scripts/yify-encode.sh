#!/bin/bash

help () {
  echo "usage: $(basename "$0") <input> <output>"
  echo "  where:"
  echo "    input - the video source file"
  echo "    output - [path +] output-file (extension: usually mp4)"
}

case $1 in
  -h | --help) help ; exit 1 ;;
esac

# exit if not enough arguments
if [[ $# -lt 2 ]] ; then
    echo "$(basename "$0"): missing arguments, see -h or --help for usage help"
    exit 1
fi

input=$1
output=$2


echo ":: encoding video with typical YIFY settings"
echo ":: starting..."

HandBrakeCLI -i $input -o $output -E fdk_faac -B 96k -6 stereo -R 44.1 -e x264 -q 27 -x cabac=1:ref=5:analyse=0x133:me=umh:subme=9:chroma-me=1:deadzone-inter=21:deadzone-intra=11:b-adapt=2:rc-lookahead=60:vbv-maxrate=10000:vbv-bufsize=10000:qpmax=69:bframes=5:b-adapt=2:direct=auto:crf-max=51:weightp=2:merange=24:chroma-qp-offset=-1:sync-lookahead=2:psy-rd=1.00,0.15:trellis=2:min-keyint=23:partitions=all

echo "[  DONE  ]"
