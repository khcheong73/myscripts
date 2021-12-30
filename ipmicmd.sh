#!/bin/bash
if [ -z $1 ] && [ -z $2 ] && [ -z $3 ]; then
  echo "$0 BMC_IP USERID PASSWD IPMI_CMD"
  exit
fi

if [ -z "$4" ]; then
  echo NO IPMI_CMD
  exit
fi

ipmitool -I lanplus -H $1 -U $2 -P $3 $4 $5 $6 $7 $8
