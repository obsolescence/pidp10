#!/bin/bash

if [ $# -eq 0 ]; then

	procs=`screen -ls pidp10 | egrep '[0-9]+\.pidp10' | wc -l`
	echo $procs
	if [ $procs -ne 0 ]; then
		screen -Dr pidp10
	fi

else
	case $1 in
		con)
			//nohup /opt/pidp10/bin/sty > /dev/null 2>&1 &
			nohup /opt/pidp10/bin/sty -e telnet localhost 1025 > /dev/null 2>&1 &
			;;
		telcon)
			nohup lxterminal --command="telnet localhost 1025" > /dev/null 2>&1 &
			;;
		vt52)
			nohup /opt/pidp10/bin/vt52 -B -b 9600 telnet localhost 10018 > /dev/null 2>&1 &
			;;
		vt05)
			nohup /opt/pidp10/bin/vt05 -B -b 9600 telnet localhost 10018 > /dev/null 2>&1 &
			;;
		tv11)
			#nohup lxterminal --command="/opt/pidp10/bin/tv11 -s 4 -p 10011 localhost" > /dev/null 2>&1 &
			screen -dmS tv11 /opt/pidp10/bin/tv11 -s 4 -p 10011 localhost
			;;
		tv11-tty)
			echo unimplemented - start manually: $1
			;;
		tvcon)
			nohup /opt/pidp10/bin/tvcon -2BS localhost > /dev/null 2>&1 &
			;;
		imlac)
			#export HOME="/opt/pidp10/bin"
			cd /opt/pidp10/bin
			nohup /opt/pidp10/bin/imlac /opt/pidp10/bin/imlac.simh > /dev/null 2>&1 &
			;;
		tek)
			nohup /opt/pidp10/bin/tek4010 -b9600 telnet localhost 10017 > /dev/null 2>&1 &
			;;
		dp3300)
			nohup /opt/pidp10/bin/dp3300 -a -B -b 4800 telnet localhost 10020 > /dev/null 2>&1 &	
			;;
		pdp6)
			echo unimplemented - start manually: $1
			;;
		pdp6-tty)
			echo unimplemented - start manually: $1
			;;
		type340)
			/opt/pidp10/bin/type340.expect	
			;;
		gt40)
			echo unimplemented - start manually: $1
			;;
		*)
			echo options are: 
			echo  [con telcon vt52 vt05 tv11 tvcon imlac tek dp3300 pdp6 type340 gt40 tv11-tty pdp6-tty]
			echo run without options, 
			echo  pdp brings you into simh - Ctrl-A d to leave
			;;
	esac
fi
