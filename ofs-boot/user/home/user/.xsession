lock_screen() {
/usr/bin/ksmserver --lockscreen &
}

[ "$1" == "/etc/X11/Sessions/Xsession" ] && . $HOME/.xinitrc || lock_screen
