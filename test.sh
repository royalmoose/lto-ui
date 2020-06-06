#!/bin/bash


#--- GENERATE USING SMART CARD RANDOM NUMBER GENERATOR--------------------------

#descriptr variable for the key
ukad="Descriptor"
keylocation="tape2.key"
gpguser="moose"

#Pull 256 bits from RNG and hash it
key=$(gpg-connect-agent "SCD RANDOM 256" /bye | sha256sum -b)

#Pull only the hash, add the descriptor and send it to gpg for encryption
echo -e "${key:0:64}\n$ukad" | gpg -e -r $gpguser -o $keylocation.gpg
echo -e "${key:0:64}\n$ukad" > $keylocation

final=$(gpg --quiet -d tape2.key.gpg | head -n 1 )
echo "$final"
sudo stenc -f /dev/sg0 -e on -a 1 -k $keylocation
shred -u $keylocation
ls
sudo stenc -f /dev/sg0 -e off -a 1
#-------------------------------------------------------------------------------
