#!/bin/bash
nmcli networking off
sudo systemctl stop NetworkManager
sudo ip link set wlp3s0 down 
sudo modprobe -r ath10k_pci
sudo modprobe -r ath10k_core
sudo modprobe ath10k_pci nohwcrypt=1 skip_otp=y
sudo ip link set wlp3s0 up
sudo rfkill unblock all
sudo systemctl start NetworkManager
nmcli networking on
