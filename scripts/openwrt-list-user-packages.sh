#!/bin/bash

# ls /overlay/upper/usr/lib/opkg/info/*.list | sed -e 's/.*\///' | sed -e 's/\.list//'

ssh -t root@192.168.1.1 "ls /rom/overlay/upper/usr/lib/opkg/info/*.list | sed -e 's/.*\\///' | sed -e 's/\\.list//'"

# ssh root@openwrt
