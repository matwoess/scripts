#!/bin/bash
for i in *.avi;
  do name=`basename $i .avi`;
  echo $name;
  ffmpeg -i $i $name.mkv || exit 1
done
