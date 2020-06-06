#!/bin/bash

backtitle="START > "

#--- ASK FOR: TAPE DRIVE PARAMETERS --------------------------------------------

parameters=$(dialog  --backtitle "$backtitle" \
        --title "LTO Details" \
        --ok-label "Next" --nocancel \
	      --output-separator "," --form "\nEnter LTO tape details:\n" 12 50 0 \
        	"Drive Location"   1 1	"/dev/sg0" 	1 17 20 0 \
          "Volume Label"     3 1	""  	      3 17 20 0 \
        	"Serial Number"    4 1	""          4 17 6  0 \
          3>&1 1>&2 2>&3 3>&-)

#Sanitise the output string:
# - Remove spaces from user inputed fields
# - Replace the comma array seperator with bash friendly space seperators
parameters=$(echo "$parameters" | tr " " _ | tr "," " ")

#Convert string to array
parametersarray=($parameters)

#Output to variables and backtitle and final command variables:
#Location
location="--device=${parametersarray[0]} "
backtitle+="${parametersarray[0]} > "
#Volume label
[ -z "${parametersarray[1]}" ] && backtitle+="[No Volume Label] > " || volumelabel="--volume-name=${parametersarray[1]} " backtitle+="Volume: ${parametersarray[1]} > "
#Volume Serial Number
[ -z "${parametersarray[2]}" ] && backtitle+="[No Serial Number] > " || volumeserial="--tape-serial=${parametersarray[2]} " backtitle+="Serial No: ${parametersarray[2]} > "

#-------------------------------------------------------------------------------


#--- ASK FOR: WIPE TAPE --------------------------------------------------------

dialog  --backtitle "$backtitle" \
        --title "Wipe tape drive?" --clear \
        --extra-button --extra-label "Short wipe" \
        --ok-label "No" \
        --cancel-label "Long Wipe" \
        --colors --yesno "\nDo you want to wipe the tape before formatting?
        \n\n\Zb\ZuWARNING\Zn\nA long wipe will take over three hours and cannot be stopped once executed." 13 40

case $? in
  0) #[OK] No Wipe
    backtitle+="No Wipe > " ;;
  1) #[Cancel] Long Wipe
    backtitle+="Long Wipe > "
    mkltfs $location --long-wipe &> /tmp/lto &
    dialog --backtitle "$backtitle" --clear --tailbox /tmp/lto 35 110;;
  3)#[Extra] Short Wipe
    backtitle+="Short Wipe > "
    mkltfs $location --wipe &> /tmp/lto &
    dialog --backtitle "$backtitle" --clear --tailbox /tmp/lto 35 110;;
  255)
    echo "ESC pressed.";;
esac

#-------------------------------------------------------------------------------


#--- ASK FOR: COMPRESSION ------------------------------------------------------

dialog  --backtitle "$backtitle" \
        --title "Compression" --clear \
        --defaultno --yesno "\nDo you want to disable compression?" 10 40

case $? in
  0) #[Yes]
    comression="--no-copression"
    backtitle+="Compression Disabled > " ;;
  1) #[No]
    backtitle+="Compression Enabled > " ;;
  255)
    echo "ESC pressed.";;
esac

#-------------------------------------------------------------------------------


#--- ASK FOR: FORCED FORMAT ----------------------------------------------------

dialog  --backtitle "$backtitle" \
        --title "Force Format" --clear \
        --defaultno --yesno "\nDo you want to force format the tape?
        \n\nThis may be required if previous attempts at formatting have failed." 10 40

case $? in
  0) #[Yes]
    forced="--forced "
    backtitle+="Forced Format > " ;;
  1) #[No]
    backtitle+="Un-forced Format > " ;;
  255)
    echo "ESC pressed.";;
esac

#-------------------------------------------------------------------------------


#--- CONFIRM ENTRY -------------------------------------------------------------
confirmation=$(echo "${backtitle:7}" | tr ">" "\n")
backtitle+="END"


dialog  --backtitle "$backtitle" \
        --title "Confirmation" --clear \
        --cr-wrap --yesno "\nSelected options:\n\n$confirmation\n\nDo you want to proceed?" 16 40

case $? ins
  0) #[Yes]
    #mkltfs $location $volumelabel $volumeserial $wipe $compression $forced 2>&1 | tee /tmp/test2 &
    echo "mkltfs $location $volumelabel $volumeserial $compression $forced" &> /tmp/lto &
    #tail -f /tmp/test2;;
    dialog --backtitle "$backtitle" --clear --tailbox /tmp/lto 35 110;;
  1) #[No]
    echo "Exiting";;
  255)
    echo "ESC pressed.";;
esac

#-------------------------------------------------------------------------------
clear
