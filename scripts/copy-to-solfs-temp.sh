#!/bin/bash
if [[ $# -lt 2 ]] ; then
    echo "[ERROR] invalid number of arguments supplied"
    echo "Please pass minimum 2 argument as following: <username> <file> [optional]<folder>"
    echo "Example: mathias.woesz copy-this.txt mathias"
    exit 1
fi

user=$1
file=$2
if [[ -z $3 ]] ; then
  folder=.
else
 folder=$3
fi

echo ":: creating .credentials"

echo "username=$user
domain=FABAGL" > ~/.credentials

echo ":: mounting solfs/temp"

mount.cifs //solfs/temp /mnt/solfs/temp -o noauto,credentials=$HOME/.credentials || exit 1

echo ":: deleting credentials file"

rm -f ~/.credentials

echo ":: creating directory $folder if not exists"

[ -d /mnt/solfs/temp/$folder ] || mkdir /mnt/solfs/temp/$folder

echo ":: copying $file -> /mnt/solfs/temp/$folder"

rsync --progress --ignore-existing $file /mnt/solfs/temp/$folder/$file || exit 1

echo ":: unmounting temp"

sudo umount /mnt/solfs/temp

echo "[  DONE  ]"
