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
    backtitle+="Generate Key > "
    ukad="Descriptor"
    keylocation="tape2.key"
    gpguser="moose"
    parameters=$(dialog  --backtitle "$backtitle" \
            --title "Generate New LTO Encryption Key" \
            --ok-label "Next" --nocancel \
    	      --output-separator "," --form "\nEnter LTO tape details:\n" 12 50 0 \
        	    "Serial Number"    1 1	""    1 17 6  0 \
            	"Key Descriptor"   2 1	"" 	  2 17 20 0 \
              "GPG UUID"         4 1	""  	4 17 20 0 \
              3>&1 1>&2 2>&3 3>&-)
    #Sanitise the output string:
    # - Remove spaces from user inputed fields
    # - Replace the comma array seperator with bash friendly space seperators
    parameters=$(echo "$parameters" | tr " " _ | tr "," " ")

    #Convert string to array
    parametersarray=($parameters)

    #Pull 256 bits from RNG and hash it
    key=$(gpg-connect-agent "SCD RANDOM 256" /bye | sha256sum -b)

    #Pull only the hash, add the descriptor and send it to gpg for encryption
    echo -e "${key:0:64}\n${parametersarray[1]}" | gpg -e -r ${parametersarray[2]} -o ${parametersarray[0]}.key.gpg --yes
    dialog  --backtitle "$backtitle" \
            --title "Generate New LTO Encryption Key" --clear \
            --msgbox "\nKey generated:\n\n${parametersarray[0]}.key.gpg" 10 38 ;;

  1) #Remove Key
    backtitle+="Remove Key"
    sudo stenc -f /dev/sg0 -e off -a 1 &> /tmp/lto &
    dialog --backtitle "$backtitle" --clear --tailbox /tmp/lto 35 110;;

  3) #Load Key
    backtitle+="Load Key"
    #ltokey=$(dialog --title "Select LTO Encryption Key" --stdout --fselect ./ 14 48)
    ltokey=$(zenity --file-selection)

    if [[ ${ltokey: -3} == "gpg" ]];then
      #Encrypted GPG file Selected
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
