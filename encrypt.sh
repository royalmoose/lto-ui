#!/bin/bash

backtitle="LTO ENCRYPTION START > "

##--- ASK TO GENERATE KEY OR LOAD KEY ------------------------------------------

#Pull encryption info from drive
status=$(sudo stenc -f /dev/sg0 --detail)

dialog  --backtitle "$backtitle" \
        --title "LTO Status" --clear \
        --ok-label "Generate Key" \
        --extra-button --extra-label "Load Key" \
        --cancel-label "Remove Key" \
        --cr-wrap --yesno "\n$status" 25 75

case $? in
  0) #Generate new key
    backtitle+="Generate Key > " ;;
  1) #Remove Key
    backtitle+="Remove Key"
    sudo stenc -f /dev/sg0 -e off -a 1 &> /tmp/lto &
    dialog --backtitle "$backtitle" --clear --tailbox /tmp/lto 35 110;;
  3) #Load Key
    backtitle+="Load Key"
    #ltokey=$(dialog --title "Select LTO Encryption Key" --stdout --fselect ./ 14 48)
    ltokey=$(zenity --file-selection)

    if [[ ${ltokey: -3} == "gpg" ]];then
      #Decrypt LTO key
      gpg --quiet -d $ltokey > lto.key
      #Send key to device
      sudo stenc -f /dev/sg0 -e on -a 1 -k lto.key &> /tmp/lto
      #Shred key
      shred -u lto.key
      dialog --backtitle "$backtitle" --clear --tailbox /tmp/lto 35 110
    else
      #Load non-GPG key
      sudo stenc -f /dev/sg0 -e on -a 1 -k $ltokey &> /tmp/lto
      dialog --backtitle "$backtitle" --clear --tailbox /tmp/lto 35 110
    fi ;;
  255)
    echo "ESC pressed.";;
esac

#-------------------------------------------------------------------------------
