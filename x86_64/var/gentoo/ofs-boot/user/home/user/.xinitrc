[ -f $HOME/.xinitrc.sh ] && . $HOME/.xinitrc.sh

. $HOME/.bashrc
source /etc/profile

#export PULSE_LATENCY_MSEC=100

export LIBGL_DRI3_DISABLE=1

setxkbmap -model pc105 -layout us,ru,ua -variant ,winkeys,winkeys -option grp:ctrl_shift_toggle
compton --vsync opengl --backend glx -b
#xsetroot -solid "#aaaaaa"

export XDG_CURRENT_DESKTOP=KDE
export PARTITIONMANAGER="sudo /usr/bin/partitionmanager"
export XCURSOR_THEME=breeze_cursors

tint2 &
exec ck-launch-session openbox-session
