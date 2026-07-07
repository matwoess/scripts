#!/bin/bash

version=$1
majorversion=${version:0:1}
url=https://cdn.kernel.org/pub/linux/kernel/v$majorversion.x/linux-$version.tar.xz
path="drivers/bluetooth/"

#exit if no argument
if [ $# -ne 1 ]; then
    echo $0: missing version argument
    exit 1
fi

echo current kernel `uname -r`

cd ~/Downloads
echo ":: changed directory to home/Downloads"

echo ":: downloading and unzipping version \"$version\" from kernel.org to home/Downloads..."
echo " - url: ($url)"

curl -sL $url | tar xpfJ - -C .

cd linux-$version
echo ":: changed directory to linux-$version"

echo ":: editing source..."
echo " - adding line to btusb.c"
sed -i '/{ USB_DEVICE(0x0cf3, 0xe360), .driver_info = BTUSB_QCA_ROME },/a \
        { USB_DEVICE(0x0489, 0xe092), .driver_info = BTUSB_QCA_ROME },' drivers/bluetooth/btusb.c
echo " - added"

echo ":: preparing for recompile..."
make mrproper
cp /usr/lib/modules/`uname -r`/build/.config ./
cp /usr/lib/modules/`uname -r`/build/Module.symvers ./
make oldconfig
make prepare && make scripts

echo ":: recompiling bluetooth module.."
make M=drivers/bluetooth

echo ":: gzipping kernel module..."
gzip drivers/bluetooth/btusb.ko

echo ":: copying to kernel directory..."
sudo cp drivers/bluetooth/btusb.ko.gz /usr/lib/modules/`uname -r`/kernel/drivers/bluetooth/

echo ":: deleting obsolete directory..."
cd ..
rm -r ~/Downloads/linux-$version

echo ":: regenerating initramfs..."
sudo mkinitcpio -p linux
