#!/bin/sh

U=$(env | grep username | cut -d'=' -f2)
P=$(env | grep password | cut -d'=' -f2)

SP=$(head -1 /etc/openvpn/vserver/ccd/$U | cut -d'#' -f2)

[ "$SP" != "$P" ] && exit 1

exit 0
