export LIBGL_DRI3_DISABLE=1
export XDG_CURRENT_DESKTOP=KDE

export IFTOP="/usr/sbin/iftop -B -m 4M"

setxkbmap -model pc105 -layout us,ru,ua -variant ,winkeys,winkeys -option grp:ctrl_shift_toggle
compton --vsync opengl --backend glx -b
tint2 &
exec openbox-session
