#!/bin/bash

help () {
  echo "usage: $(basename "$0") <file1> <file2> <delay>"
  echo "  where:"
  echo "    file1 - the video source file"
  echo "    file2 - the audio source file"
  echo "    delay - [optional] the audio delay in seconds (negative value for audio to be earlier than video)"
}

case $1 in
  -h | --help) help ; exit 1 ;;
esac

# exit if not enough arguments
if [[ $# -lt 2 ]] ; then
    echo "$(basename "$0"): missing arguments, see -h or --help for usage help"
    exit 1
fi

file1=$1
file2=$2

if [[ -z $3 ]] ; then
  delay=0
else
 delay=$3
fi

echo ":: putting video of <file1> together with audio of <file2> with delay $delay"
echo ":: starting..."

ffmpeg -i $file1 -itsoffset $delay -i $file2 -c copy -map 0:v:0 -map 1:a:0 -ac 2 out.mp4

echo "[  DONE  ]"
