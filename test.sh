#!/bin/bash


#--- GENERATE USING SMART CARD RANDOM NUMBER GENERATOR--------------------------

#descriptr variable for the key
ukad="Descriptor"
keylocation="tape2.key"

#Pull 256 bits from RNG and hash it
key=$(gpg-connect-agent "SCD RANDOM 256" /bye | sha256sum -b)

#Pull only the hash, add the descriptor and send it to a file
echo -e "${key:0:64}\n$ukad" > $keylocation

#-------------------------------------------------------------------------------
