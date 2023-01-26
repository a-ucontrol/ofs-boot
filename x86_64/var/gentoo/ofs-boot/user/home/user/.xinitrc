source $HOME/.bashrc

#export PULSE_LATENCY_MSEC=100
#pactl load-module module-dbus-protocol
#pactl load-module module-equalizer-sink

setxkbmap -model pc105 -layout us,ru -variant ,winkeys,winkeys -option grp:alt_shift_toggle
#picom --vsync opengl --backend glx -b
#xsetroot -solid "#aaaaaa"

#exec xterm

export XDG_CURRENT_DESKTOP=KDE
export PARTITIONMANAGER="sudo /usr/bin/partitionmanager"
export XCURSOR_THEME=breeze_cursors

tint2 &
exec openbox-session
