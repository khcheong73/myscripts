#!/bin/bash

LSPCI=/tmp/lspci.txt
LSPCI_VV=/tmp/lspci_vv.txt
DEVICE="PLX\|NVIDIA"

lspci > $LSPCI
lspci -vv > $LSPCI_VV

NUM_DEV=$(cat $LSPCI | grep $DEVICE | wc -l)
NUM_PLX=$(cat $LSPCI | grep PLX | wc -l)
NUM_NVIDIA=$(cat $LSPCI | grep NVIDIA | wc -l)
DEV_ADDR=$(lspci | grep $DEVICE | cut -d' ' -f1)

lspci -tv | grep --color $DEVICE

printf "[PLX devices = %s, NVIDIA devices = %s ]\n" $NUM_PLX $NUM_NVIDIA
#printf "[NVIDIA devices = %s ]\n" $NUM_NVIDIA

for i in $DEV_ADDR; do
  DEV_VEN=`lspci -m -s $i | cut -d'"' -f4 | cut -d' ' -f1`
  DEV_NAME=`lspci -m -s $i | cut -d'"' -f6`
  LNK_SPEED=`lspci -vv -s $i | grep LnkSta: | awk '{printf $3}' | sed 's/,//g'`
  LNK_WIDTH=`lspci -vv -s $i | grep LnkSta: | awk '{printf $5}' | sed 's/,//g'`
  printf " %s %8s %4s  %-6s, " $i $LNK_SPEED $LNK_WIDTH $DEV_VEN
  echo $DEV_NAME
#  echo $i $DEV_VEN $DEV_NAME $LNK_SPEED $LNK_WIDTH
done

rm -rf $LSPCI $LSPCI_VV

exit
