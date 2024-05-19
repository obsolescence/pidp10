#! /bin/bash

### BEGIN INIT INFO
# Provides:		pidp10
# Required-Start:	$syslog
# Required-Stop:	$syslog
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	PiDP-10 emulator
### END INIT INFO

# Init script for pidp10.  
# Snippets taken from original author: Mark G Thomas <mark@misty.com> 2015-05-09

PATH=/sbin:/usr/sbin:/bin:/usr/bin
umask 022
. /lib/lsb/init-functions

boot_number=$2
argc=$#
pidp10="/opt/pidp10/bin/pidp10"
pidp_dir=`dirname $pidp10`
pidp_bin=`basename $pidp10`


# Requires screen utility for detached pidp10 console functionality.
#
test -x /usr/bin/screen || ( echo "screen not found" && exit 0 )
test -x $pidp10 || ( echo "pidp10 not found" && exit 0 )

# Check if pidp10 is already runnning under screen.
#
is_running() {
	procs=`screen -ls pidp10 | egrep '[0-9]+\.pidp10' | wc -l`
	return $procs
}

do_stat() {
	is_running
	status=$?
	if [ $status -gt 0 ]; then
	    echo "PiDP-10 is up." >&2
	    return $status
	else
	    echo "PiDP-10 is down." >&2
	    return $status
	fi
}

do_start() {
	is_running
	if [ $? -gt 0 ]; then
	    echo "PiDP-10 is already running, not starting again." >&2
	    exit 0
	fi

	if [[ $argc -eq 2 ||  ! -z "$boot_number" ]]; then
		file_extension=".pi"
		sys=$boot_number
	else
		file_extension=".pidp"
		/opt/pidp10/bin/scansw10
		boot_number=$?
		sys=`printf "%04o" $boot_number`
	fi

	sel=`awk '$1 == '$sys' { sys = $2; exit } END { if(sys) print sys; else print "hills-blinky" }' < /opt/pidp10/systems/selections`
	if [ "$boot_number" -ge 16 ]; then
		pidp_bin="pdp10-ki"
	fi
	if [ "$boot_number" -ge 64 ]; then
		pidp_bin="pdp10-kl"
	fi

	echo "Starting PiDP-10 with boot option $sys"
	cd $pidp_dir
	echo screen -dmS pidp10 ./$pidp_bin /opt/pidp10/systems/$sel/boot$file_extension
	screen -dmS pidp10 ./$pidp_bin /opt/pidp10/systems/$sel/boot$file_extension
	#screen -dmS pidp10 ./$pidp_bin bootscript.simh $boot_number
	status=$?
	echo $status
	return $status
}

do_stop() {
	is_running
	if [ $? -eq 0 ]; then
	    echo "PiDP-10 is already stopped." >&2
	    status=1
	else
	    echo "Stopping PiDP-10" "pidp"
	    # this will make simh respond to quit signal, otherwise 
	    /opt/pidp10/bin/stop.expect
		#leaving screen *and* killing the process are unnecessary.
		#superstition.
	    screen -S pidp10 -X quit
	    pkill -9 pidp10
	    status=$?
	    echo $status
	fi

	# check for a running tv11 as well, and close it
	if pgrep -x "tv11" >/dev/null; then
		echo Stopping tv11 also...
		pkill -2 tv11
	fi
	return $status
}

case "$1" in
  start)
	do_start
	;;

  stop)
	do_stop
	;;

  restart)
	do_stop
	sleep 8
	do_start
	;;

  status)
	screen -ls pidp10 | egrep '[0-9]+\.pidp10'
	;;

  stat)
	do_stat
	;;
  ?)
	echo "Usage: pdpcontrol {start|stop|restart|status|stat}" || true
	exit 1
	;;
  *)
	do_stat
	if [ $status == 0 ]; then
		read -p "(S)tart, Start with boot (number), or (C)ancel? " respx
		case $respx in
			[Ss]* )
				do_start
				;;
			[0-9]* )
				boot_number=$respx
				# convert to decimal
				#boot_number=$((8#$ooot_number))
				do_start
				;;
			[Cc]* )
				exit 1
				;;
			* )
				echo "Please answer with S, a boot number, or C.";;
		esac
	else
		read -p "(S)top or (C)ancel? " respx
		case $respx in
			[Ss]* )
				do_stop
				;;
			[Cc]* )
				exit 1
				;;
			* )
				echo "Please answer with S or C.";;
		esac
	fi
esac
exit 0

