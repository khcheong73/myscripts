#!/bin/bash

## Script to gather inventory
## 1st release: 2021.12.14. Kevin Cheong

REQTOOLS="ipmitool smartmontools bc pciutils net-tools"
yum install -y $REQTOOLS > /dev/null

# System information
DMISYS=$(dmidecode -t system)
IPMIMC=$(ipmitool mc info)

MODEL=$(echo "$DMISYS" | grep "Product Name" | cut -d':' -f2)
SYSSN=$(echo "$DMISYS" | grep "Serial Number" | awk '{print $3}')
BIOSV=$(dmidecode -t bios | grep "Version" | awk '{print $2}')
BMCFWM=$(echo "$IPMIMC" | grep "Firmware Revision" | awk '{print $4}')
BMCFWm=`echo $((16#$(echo "$IPMIMC" | grep -A1 Aux |grep 0x | cut -d"x" -f2)))`
BMCV=$BMCFWM.$BMCFWm
BMCMAC=$(ipmitool lan print | grep "MAC Address" | awk '{print $4}')

echo [ System ]
echo "Model:" $MODEL
echo "Serial:" $SYSSN

echo; echo [ Motherboard ]
dmidecode -H 0x2 | grep "Manuafacturer\|Product\ Name\|Version\|Serial" | while read line; do
  echo $line
done
printf "BIOS Version:\t%s\n" $BIOSV
printf "BMC Version:\t%s\n" $BMCV
printf "BMC MAC Addr:\t%s\n" $BMCMAC

# CPU information
echo; echo [ Processor ]
printf "%sx %s\n" $(lscpu | grep Socket\(s\) | awk '{print $2}') "$(echo $(lscpu | grep 'Model\ name' | grep -v BIOS | cut -d':' -f2))"
lscpu | grep -i 'Core(s)\|Thread(s)'

# Memory information
echo;echo "[ Memory ]"
#MEMHANDLE=$(dmidecode -t memory | grep "DMI type 17" | cut -d',' -f1 | awk '{print $2}')
MEMHANDLE=$(dmidecode -t 17 | grep Handle | grep -v "Array\|Error" | cut -d',' -f1 | awk '{print $2}')
for i in $MEMHANDLE; do
  if [ -z "$(dmidecode -H $i | grep 'No Module Installed')" ]; then
    DMIMEM=$(dmidecode -H $i)
    MEMSIZE=$(echo "$DMIMEM" | grep Size: | grep -v "Volatile\|Cache\|Logical" | cut -d':' -f2)
    MEMLOCA=$(echo "$DMIMEM" | grep Locator | grep -v Bank | cut -d':' -f2)
    MEMTYPE=$(echo "$DMIMEM" | grep Type: | cut -d':' -f2)
    MEMMFG=$(echo "$DMIMEM" | grep Manufacturer | grep -v "Module\|Subsystem" | cut -d':' -f2)
    MEMPN=$(echo "$DMIMEM" | grep "Part\ Number" | cut -d':' -f2)
    MEMSPEED=$(echo "$DMIMEM" | grep Speed | grep -vi config | cut -d':' -f2)
    MEMCFGSPEED=$(echo "$DMIMEM" | grep Speed | grep Config | cut -d':' -f2)
   
#    printf "%s %s, %s, %s, %s, %s %s, %s, %s, %s %s\n" $(dmidecode -H $i | grep "Size:\|Locator:\|Type:\|Speed:\|Part\ Number\|Manufacturer" | cut -d':' -f2)
printf "%s\t%s, %s, %s, %s, %s, %s\n" "$(echo $MEMLOCA)" "$(echo $MEMSIZE)" $MEMTYPE "$(echo $MEMMFG)" $MEMPN "$(echo $MEMSPEED)" "$(echo $MEMCFGSPEED)"
  fi
done

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
    DEVMODEL=$(echo "$DRVINFO" | grep "Device\ Model\|Product\|Model\ Number" | cut -d':' -f2)
    DRVCAPA=$(echo "$DRVINFO" | grep "User\ Capacity\|Total\ NVM\ Capacity" | cut -d'[' -f2 | cut -d']' -f1)
    DRVSN=$(echo "$DRVINFO" | grep "Serial\ Number" | cut -d':' -f2 )
    DRVROTA=$(echo "$DRVINFO" | grep "Rotation\ Rate\|Device\ type" | cut -d':' -f2)
      if [ -z "$DRVROTA" ]; then 
	if [[ $i =~ "nvme" ]]; then
	  DRVROTA="NVMe SSD"
	else     
          DRVROTA="unknown"
	fi
     fi
#    if [ -z "$(echo $MRDRVSN | grep '$DRVSN')" ]; then
#    if [[ "$MRDRVSNALL" =~ "$DRVSN" ]]; then
      printf "%s\t%s / %s / %s\n" $i "$(echo $DEVMODEL)" "$DRVCAPA" "$(echo $DRVROTA)"
#    fi
  done
fi

# Drives on MegaRAID
if [ ! -z "$(smartctl --scan | grep -i megaraid)" ]; then
  echo; echo "[ Drives behind MegaRAID ]"
  smartctl --scan | grep -i megaraid | while read line; do
    DRVINFO=$(smartctl -d $(echo $line | awk '{print $3}') -i $(echo $line | awk '{print $1}'))
#    MODELFAM=$(echo "$DRVINFO" | grep "Model\ Family" | cut -d':' -f2)
    DEVMODEL=$(echo "$DRVINFO" | grep "Device\ Model" | cut -d':' -f2)
    DRVCAPA=$(echo "$DRVINFO" | grep "User\ Capacity" | cut -d'[' -f2 | cut -d']' -f1)
    DRVSN=$(echo "$DRVINFO" | grep "Serial\ Number" | cut -d':' -f2 )
    DRVROTA=$(echo "$DRVINFO" | grep "Rotation\ Rate" | cut -d':' -f2)
    if [[ "$DRVSNALL" =~ "$DRVSN" ]]; then
      printf ""
    else
      printf "%s\t%s / %s / %s\n" "$(echo $line | cut -d"#" -f1)" "$(echo $DEVMODEL)" "$DRVCAPA" "$(echo $DRVROTA)"
    fi
  done
fi

# RAID controller & drive information
if [ ! -z $(whereis storcli64 | cut -d':' -f2) ]; then
  NUMRAID=$(storcli64 show | grep "Number of Controllers" | awk '{print $5}')
else
  NUMRAID=0
fi
#storcli64 show | grep "Number of Controllers"

for (( i=0; i< $NUMRAID; i++ )); do
  echo; echo "[ RAID Controller #$i ]"
  storcli64 /c$i show all | grep -v "Support\|Download" | grep "Model\ =\|Board\ Memory\|Firmware\|Physical\ Drives\|Virtual\ Drives"
done

## Ethernet MAC address
echo; echo "[ Ethernet ]"
for i in `ls /sys/class/net | grep "en\|eth"`; do
  ETHMAC=`ip link show $i | grep ether | awk '{print $2}'`
  for j in `lspci | grep Ethernet | awk '{print $1}'`; do
    if [ ! -z  "`ls -l /sys/class/net/$i | grep $j`" ]; then
      ETH_VEN=`lspci -m -s $j | cut -d'"' -f4`
      ETH_NAME=`lspci -m -s $j | cut -d'"' -f6`
    fi
  done

  printf "%s\t%s, %s, %s\n" $i $ETHMAC "${ETH_VEN}" "${ETH_NAME}"
done

## InfiniBand
if [ ! -z "$(lspci | grep -i infiniband)" ]; then
  echo; echo "[ InfiniBand ]"
  for i in `ls /sys/class/net | grep "ib"`; do
    IBGUID=`ip link show $i | grep -i infiniband | awk '{print $2}'`
    for j in `lspci | grep -i infiniband | awk '{print $1}'`; do
      if [ ! -z  "`ls -l /sys/class/net/$i | grep $j`" ]; then
        IB_VEN=`lspci -m -s $j | cut -d'"' -f4`
        IB_NAME=`lspci -m -s $j | cut -d'"' -f6`
      fi
    done

    printf "%s\t%s, %s, %s\n" $i $(echo 0x${IBGUID:36}| sed -e s/":"//g) "${IB_VEN}" "${IB_NAME}"
  done
fi

## GPU information
DEVICE="NVIDIA\|PLX"
if [ ! -z "$(lspci | grep -i $DEVICE)" ]; then
  echo; echo "[ GPU ]"
  LSPCI=`lspci`

  DEV_ADDR=$(echo "$LSPCI" | grep $DEVICE | awk '{print $1}')

  for i in $DEV_ADDR; do
    DEV_VEN=`lspci -m -s $i | cut -d'"' -f4` 
    DEV_NAME=`lspci -m -s $i | cut -d'"' -f6`
    LNK_SPEED=`lspci -vv -s $i | grep LnkSta: | awk '{printf $3}' | sed 's/,//g'`
    LNK_WIDTH=`lspci -vv -s $i | grep LnkSta: | awk '{printf $5}' | sed 's/,//g'`
    printf "%s, %s, %s, %s, %s\n" $i "$DEV_VEN" "$DEV_NAME" $LNK_SPEED $LNK_WIDTH
  done
fi
