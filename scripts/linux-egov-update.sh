#!/bin/bash
if [[ $# -lt 3 ]] ; then
    echo "[ERROR] invalid number of arguments supplied"
    echo "Please pass 3 arguments as following: <username> <project> <version>"
    echo "Example: mathias.woesz BSI 140013"
    exit 1
fi

user=$1
project=$2
version=$3

echo ":: creating .credentials"

echo "username=$user
domain=FABAGL" > ~/.credentials

echo ":: mounting solfs/KitsSolutions"

mount.cifs //solfs/KitsSolutions /mnt/solfs/KitsSolutions -o noauto,credentials=$HOME/.credentials || exit 1

echo ":: deleting credentials file"

rm -f ~/.credentials

echo ":: creating directory iso if not exists"

[ -d ~/iso ] || mkdir ~/iso

echo ":: copying /mnt/solfs/KitsSolutions/$project/PrereleaseBuild_$version/$project.iso -> ~/iso"

rsync --progress --ignore-existing /mnt/solfs/KitsSolutions/$project/PrereleaseBuild_$version/$project.iso ~/iso/$project.iso || exit 1

echo ":: unmounting KitsSolutions"

umount /mnt/solfs/KitsSolutions

echo ":: mounting iso as readonly media"

[ -d /media/iso ] || mkdir /media/iso
mount -t iso9660  -o loop ~/iso/$project.iso /media/iso

echo ":: executing setup.sh"

if [ -z "${DISPLAY}" ] || [ "${DISPLAY}" = "localhost:10.0" ] ; then
  DISPLAY=:0.0
fi

/media/iso/setup.sh fsc_unattended=yes fsc_agreement=accept fsc_installmode=update

echo ":: unmounting iso"

umount /media/iso

echo "[  DONE  ]"
