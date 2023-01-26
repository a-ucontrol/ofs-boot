export XDG_CURRENT_DESKTOP=KDE

setxkbmap -model pc105 -layout us,ru -variant ,winkeys,winkeys -option grp:ctrl_alt_toggle
#compton --vsync opengl --backend glx -b

tint2 &
exec openbox-session
