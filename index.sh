#!/bin/bash

backtitle="LTO Toolkit"

option=$(dialog  --backtitle "$backtitle" \
        --title "LTO Toolkit Menu" \
        --ok-label "Run" --cancel-label "Exit" \
	      --menu "\nSelect Option:\n" 12 50 0 \
        	1 "NFS Tools" \
          2 "LTO Encryption Tools"   \
        	3 "LTO Tape Format"  \
          4 "LTO Mount Tape" 2>&1 >/dev/tty)

case $option in
  1) #[OK] No Wipe
    echo "NFS" ;;
  2) #[Cancel] Long Wipe
    ./encrypt.sh;;
  3)#[Extra] Short Wipe
    ./format.sh;;
  4)#[Extra] Short Wipe
    echo "Mount";;
  255)
    echo "ESC pressed.";;
esac
clear
