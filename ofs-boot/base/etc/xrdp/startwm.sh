#!/bin/sh

# try hard to respect Gentoo's wm choice
. /etc/profile
[ -f /etc/rc.conf ] && . /etc/rc.conf
export XSESSION

[ -f ~/.xinitrc ] && . ~/.xinitrc

. /etc/X11/xinit/xinitrc
