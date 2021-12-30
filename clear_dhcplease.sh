#!/bin/bash

rm -f /var/lib/dhcpd/dhcpd.leases
touch /var/lib/dhcpd/dhcpd.leases

systemctl restart dhcpd
