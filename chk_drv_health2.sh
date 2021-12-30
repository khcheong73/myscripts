#!/bin/bash

## Gathering SN from all drives
if [ ! -z "$(smartctl --scan | grep -v bus)" ]; then
  DRVSNALL=$(for i in $(smartctl --scan | grep -v bus | awk '{print $1}'); do
    smartctl -i $i | grep "Serial\ Number" | cut -d':' -f2
    done
  )
fi

if [ ! -z "$(smartctl --scan | grep -i megaraid)" ]; then
  MRDRVSNALL=$(smartctl --scan | grep -i megaraid | while read line; do
    smartctl -d $(echo $line | awk '{print $3}') -i $(echo $line | awk '{print $1}') | grep "Serial\ Number" | cut -d':' -f2
    done
  )
fi


# Drives on onboard controller
DRV=$(smartctl --scan | grep -v megaraid | awk '{print $1}')
if [ ! -z "$(smartctl --scan | grep -v megaraid)" ]; then
  echo; echo "[ Drives on OS-detected ]"
  for i in $DRV; do
    DRVINFO=$(smartctl -i $i)
    DRVSN=$(echo "$DRVINFO" | grep "Serial\ Number" | cut -d':' -f2 )
    echo "#" $i
    smartctl -A $i | grep -v "Multi" | grep "Timeout\|Error"
    echo
  done
fi

# Drives on MegaRAID
if [ ! -z "$(smartctl --scan | grep -i megaraid)" ]; then
  echo; echo "[ Drives behind MegaRAID ]"
  smartctl --scan | grep -i megaraid | while read line; do
    DRVINFO=$(smartctl -d $(echo $line | awk '{print $3}') -i $(echo $line | awk '{print $1}'))
#    MODELFAM=$(echo "$DRVINFO" | grep "Model\ Family" | cut -d':' -f2)
#    DEVMODEL=$(echo "$DRVINFO" | grep "Device\ Model" | cut -d':' -f2)
#    DRVCAPA=$(echo "$DRVINFO" | grep "User\ Capacity" | cut -d'[' -f2 | cut -d']' -f1)
    DRVSN=$(echo "$DRVINFO" | grep "Serial\ Number" | cut -d':' -f2 )
#    DRVROTA=$(echo "$DRVINFO" | grep "Rotation\ Rate" | cut -d':' -f2)
    if [[ "$DRVSNALL" =~ "$DRVSN" ]]; then
      printf ""
    else
      echo "#" $line | awk '{printf "%s %s %s\n", $1, $2, $4}'
      smartctl -d $(echo $line | awk '{print $3}') -A $(echo $line | awk '{print $1}') | grep -v "Multi" | grep "Timeout\|Error" 
      echo
    fi
  done
fi

