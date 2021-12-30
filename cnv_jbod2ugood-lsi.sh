#!/bin/bash

if [ -z $1 ]; then
  echo No Input!
  echo Usage: $0 [eX:sY] or [all]
  echo
  storcli64 /c0 /eall /sall show | grep "SATA\|SAS"
  exit
fi

while [ $1 != "all" ]; do
  EID=`echo $1 | cut -d':' -f1`
  SID=`echo $1 | cut -d':' -f2`
  storcli64 /c0 /e$EID /s$SID set good force
  storcli64 /c0 show
  exit
done

## make all JBOD to UGood
for i in `storcli64 /c0 /eall /sall show | grep "SATA\|SAS" | grep JBOD | awk '{print $1}'`; do
  EID=`echo $i | cut -d':' -f1`
  SID=`echo $i | cut -d':' -f2`
  storcli64 /c0 /e$EID /s$SID set good force
done

echo
storcli64 /c0 /eall /sall show
