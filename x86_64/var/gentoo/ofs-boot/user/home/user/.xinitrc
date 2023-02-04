setxkbmap -model pc105 -layout us,ru -variant ,winkeys,winkeys -option grp:alt_shift_toggle
#picom --vsync opengl --backend glx -b
#xsetroot -solid "#aaaaaa"

#exec xterm

tint2 &
exec openbox-session
