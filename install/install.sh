#!/bin/bash
#
#
# install script for PiDP-10
# v0.20240304
#
# check this script is NOT run as root
if [ "$(whoami)" == "root" ]; then
    echo script must NOT be run as root
    exit 1
fi

if [ ! -d "/opt/pidp10" ]; then
    echo clone git repo into /opt/
    exit 1
fi

echo
echo
echo PiDP-10 install script
echo ======================
echo This script is minimally invasive to your Linux. All it does outside
echo its own directory is, if you allow, \(a\) make 2 links in \/usr\/bin and
echo \(b\) add \'pdpcontrol\' to your wayfire.ini or \~\/.profile
echo
echo The script can be re-run later on to add the source code and its 
echo dependencies. Re-running the script and answering \'n\' to questions
echo will leave those things unchanged. So it will *not* undo anything
echo that is already installed.
echo
echo Too Long, Didn\'t Read?
echo Just say Yes to everything except say No to \'install source code\'
echo and to \'install source code dependencies\'. 
echo
echo
echo NEW SIMULATOR VERSION FROM RICHARD CORNWELL
echo boot sequence for ITS is now: press STOP, press READ IN, go to the
echo Teletype and enter ITS\<enter\>\<esc\>G
echo
echo

read -p "Set required access privileges to pidp10 simulator? " yn
case $yn in
    [Yy]* )
	    # make sure that the directory does not have root ownership
	    # (in case the user did a simple git clone instead of 
	    #  sudo -u pi git clone...)
	    myusername=$(whoami)
	    mygroup=$(id -g -n)
	    sudo chown -R $myusername:$mygroup /opt/pidp10
	    # make sure pidp10 simulator has the right privileges
	    # to access GPIO with root privileges:
	    sudo chmod +s /opt/pidp10/bin/pidp10
	    # to run a RT thread:
	    sudo setcap cap_sys_nice+ep /opt/pidp10/bin/pidp10
	    ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# Copy control scripts (pdpcontrol, pdp) to /usr/local/bin?
# ---------------------------
echo
read -p "Copy control script links (pdpcontrol, pdp) to /usr/local/bin? " yn
case $yn in
    [Yy]* ) 
	    sudo ln -i -s /opt/pidp10/bin/pdp.sh /usr/local/bin/pdp
	    sudo ln -i -s /opt/pidp10/bin/pdpcontrol.sh /usr/local/bin/pdpcontrol
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# Install required dependencies?
# ---------------------------
echo
read -p "Install required dependencies for running the PiDP-10? " yn
case $yn in
    [Yy]* ) 
        # update first...
        sudo apt-get update
        # for simh:
	sudo apt install -y libpcre3
        sudo apt install -y libsdl2-image-dev
        sudo apt install -y libsdl2-net-dev
	sudo apt install -y libvdeplug2
	sudo apt install -y libpcap-dev
	#the Pi does not come with telnet installed, so --
        sudo apt-get install -y telnet
        sudo apt-get install -y telnetd
	# for pdpcontrol: 
	sudo apt-get -y install expect
        # Install screen
        sudo apt-get install -y screen
	# Install Tilix, used for pdp view
	sudo apt -y install tilix
	sudo apt -y install dconf-editor dconf-cli
	dconf load /com/gexperts/Tilix/ </opt/pidp10/install/pidp10tilix.conf
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# download manual
# ---------------------------
echo
read -p "Download manual to /opt/pidp10/bin/manual.docx (MS Word format)? " yn
case $yn in
    [Yy]* ) 
        echo -----------------------
        echo Download
        wget -O /opt/pidp10/manual.docx https://pidp.net/pidp10-sw/manual.docx
        echo -----------------------
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# install ITS disk images
# ---------------------------
echo
read -p "Download and install ITS disk images? " yn
case $yn in
    [Yy]* ) 
        echo -----------------------
        echo Downloading PDP-10 ITS disk images
        wget -O /opt/pidp10/systems/its/its-system.zip https://pidp.net/pidp10-sw/its-system.zip
	unzip -d /opt/pidp10/systems/its /opt/pidp10/systems/its/its-system.zip
        echo -----------------------
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# install TOPS-10 disk images
# ---------------------------
echo
echo "NOTE: TOPS-10 disk images were updated on 2024-04-27, if in doubt say yes:"
echo
read -p "Download and install TOPS-10 disk images? " yn
case $yn in
    [Yy]* ) 
        echo -----------------------
        echo Downloading TOPS-10 disk images
        wget -O /opt/pidp10/systems/tops10-603/tops603ka.zip https://pidp.net/pidp10-sw/tops603ka.zip
        unzip -d /opt/pidp10/systems/tops10-603 /opt/pidp10/systems/tops10-603/tops603ka.zip
        echo -----------------------
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# install TOPS-20 disk images
# ---------------------------
echo
read -p "Download and install TOPS-20 disk images? " yn
case $yn in
    [Yy]* ) 
        echo -----------------------
        echo Downloading TOPS-20 disk images
        wget -O /opt/pidp10/systems/tops20/tops20-panda.zip https://pidp.net/pidp10-sw/tops20-panda.zip
	unzip -d /opt/pidp10/systems/tops20 /opt/pidp10/systems/tops20/tops20-panda.zip
        echo -----------------------
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


## ---------------------------
## allow fall-back to old simulator
## ---------------------------
#
#echo
#read -p "Use currently installed PDP-10 simulator (yes makes sense)? " ynx
#case $ynx in
#	[Yy]* ) 
#		echo Leaving things untouched
#		;;
#	[Nn]* ) 
#		read -p "Install (p)revious or (c)urrent PDP-10 simulator, or (l)eave as-is? " yn
#		case $yn in
#			[Pp]* ) 
#				echo copying pidp10.old to pidp10
#				cp /opt/pidp10/bin/pidp10.old /opt/pidp10/bin/pidp10
#				# make sure pidp10 simulator has the right privileges
#				# to access GPIO with root privileges:
#				sudo chmod +s /opt/pidp10/bin/pidp10
#				# to run a RT thread:
#				sudo setcap cap_sys_nice+ep /opt/pidp10/bin/pidp10
#				;;
#			[Cc]* ) 
#				echo copying pdp10-ka to pidp10
#				cp /opt/pidp10/bin/pdp10-ka /opt/pidp10/bin/pidp10
#				# make sure pidp10 simulator has the right privileges
#				# to access GPIO with root privileges:
#				sudo chmod +s /opt/pidp10/bin/pidp10
#				# to run a RT thread:
#				sudo setcap cap_sys_nice+ep /opt/pidp10/bin/pidp10
#				;;
#			[Ll]* ) 
#				echo Leaving things untouched from how they were
#				;;
#			* ) 
#				echo "Please answer p,c, or in case of doubt, l."
#				;;
#		esac
#		;;
#	* ) 
#		echo "Please answer yes or no."
#		;;
#esac


# ---------------------------
# install source code of Richard Cornwell's PDP-10 emulators
# ---------------------------
echo
read -p "Download Richard Cornwell's PDP-10 emulator source code? " yn
case $yn in
    [Yy]* ) 
        cd /opt/pidp10/src
	rm -rf pidp10
        git clone https://github.com/rcornwell/pidp10
        # 20240312 delete duplicate files in Richard's pidp10 fork, we want the emulator
	# and not a duplicate of all the other pidp10 files, that we already have
	rm -r /opt/pidp10/src/pidp10/systems
	rm -r /opt/pidp10/src/pidp10/install
	rm -r /opt/pidp10/src/pidp10/bin
	rm -r /opt/pidp10/src/pidp10/src/panama5
	rm -r /opt/pidp10/src/pidp10/src/pidp10-test
	rm -r /opt/pidp10/src/pidp10/src/scansw10
	rm -r /opt/pidp10/src/pidp10/src/sty33
        #git submodule sync
        #git submodule update --init --recursive
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac




# ---------------------------
# install Lars Brinkhoff's full ITS project
# ---------------------------
echo
read -p "Download Lars Brinkhoff's ITS project source code? " yn
case $yn in
    [Yy]* ) 
        cd /opt/pidp10/src
	rm -rf its 
        git clone https://github.com/PDP-10/its.git
        # get all the submodules (vt05, tektronix, etc)
        cd its
        git submodule sync
        git submodule update --init --recursive
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# install dependencies for compiling source code
# ---------------------------
echo
read -p "Install add'l dependencies for compiling the source code? " yn
case $yn in
    [Yy]* ) 
        # update first...
        sudo apt-get update
        # for its install process:
        sudo apt-get -y install autoconf
        # for graphics options in simh:
        sudo apt-get -y install libsdl2-dev
        sudo apt-get install -y libgtk-3-dev
        # for simh:
	sudo apt install -y libpcre3-dev
	sudo apt install -y libvdeplug2
	# addl from Lars' its/build/dependencies script
	sudo apt-get install -y libegl1-mesa-dev libgles2-mesa-dev
	# for networking support in simh:
	sudo apt-get install -y libpcap-dev
        sudo apt-get install -y libvdeplug-dev
        #Install readline, used for command-line editing in simh
        sudo apt-get install -y libreadline-dev
        #the above might be superceded by the one below now - at least for the Pi
#CHECK!
        sudo apt install -y libedit-dev
	# for sty:
	# this one I'm not sure of --
	sudo apt install -y libx11-dev libxt-dev	//not xft, fixed
	#
	sudo apt-get install -y libsdl2-mixer-dev  
	sudo apt-get install -y libsdl2-ttf-dev  
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# let raspi-config enable i2c, VNC, X11-not-Wayland?
# ---------------------------
echo
read -p "Let raspi-config enable i2c, VNC? " yn
case $yn in
    [Yy]* ) 
	# enable I2C on the Pi
	sudo raspi-config nonint do_i2c 0
	# enable vnc
	sudo raspi-config nonint do_vnc 0
	# switch from Wayland to X11
	# sudo raspi-config nonint do_wayland W1
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# Start up the PDP-10 automatically when logging in?
# ---------------------------
echo
append_to_file() {
	# first, make backup copy of .bashrc...
        test ! -f $1.backup && cp -p $1 $1.backup
        # add the line to profile if not there yet
        if grep -xq "pdpcontrol start" $1
        then
            echo profile modification already done, OK.
        else
            sed -e "\$apdpcontrol start" -i $1
        fi
}
append_to_wayland() {
	# first, make backup copy of .bashrc...
        test ! -f $1.backup && cp -p $1 $1.backup
        # add the line to wayfire.ini if not there yet
        if grep -xq "pdpcontrol start" $1
        then
            echo wayfire.ini modification already done, OK.
        else
            sed -e "\$a\ \n\[autostart]\npidp = pdpcontrol start" -i $1
	    echo wayfire.ini modified with autostart
        fi
}

# Wayland...of course has a problem doing things the old way, so...
if [ ! -z "$WAYLAND_DISPLAY" ]; then
	read -p "Automatically start the PiDP-10 core when logging in? " yn
	echo "...running under Wayland, would modify wayfire.ini..."
	case $yn in
		[Yy]* ) 
			echo "testing for wayfire.ini"
			if [ -f "$HOME/.config/wayfire.ini" ]; then

				if grep -q "pdpcontrol start" "$HOME/.config/wayfire.ini" 
				then
					echo "...Autostart already in wayfire.ini"
				else
					append_to_wayland "$HOME/.config/wayfire.ini"
					echo "...Autostart added to wayfire.ini"
				fi
			else
				echo "...wayfire.ini not found. Odd. Skipping autorun"
			fi
			# also, check if pdpcontrol start was left from a previous install
			# because up til 20240427 install always used .profile, even under Wayland.
			# if so, remove it
			if [ -f "$HOME/.profile" ]; then
				if grep -xq "pdpcontrol start" "$HOME/.profile"
				then
					echo removing pdpcontrol from .profile
					sed -i '/pdpcontrol start/d' "$HOME/.profile"
					echo removed pdpcontrol from .profile
				else
					echo no need to change .profile, pdpcontrol not in it
				fi
			elif [ -f "$HOME/.bash_profile" ]; then
				if grep -xq "pdpcontrol start" "$HOME/.bash_profile"
				then
					echo removing pdpcontrol from .bash_profile
					sed -i '/pdpcontrol start/d' "$HOME/.bash_profile"
					echo removed pdpcontrol from .bash_profile
				else
					echo no need to change .bash_profile, pdpcontrol not in it
				fi
			else
				echo .profile or .bash_profile not found. Odd. 
			fi
			;;
		[Nn]* ) ;;
		* ) echo "Please answer yes or no.";;
	esac
#--- patch 20240501
#--- problem: previous version checked for Wayland, then X11. But forgot that some people install headless
#--- so this is removed:
#in case running under X11:
#elif [ ! -z "$DISPLAY" ]; then
#--- and this installs autostart for both X11 and headless (or, for anything else than Wayland):
else
	read -p "Automatically start the PiDP-10 core when logging in? " yn
	echo "not running Wayland, so modifying .profile or .bash_profile..."
	echo
	echo "-------------------------------------------------------------------------------"
	echo "Please read this:"
	echo "The Raspberry Pi GUI switched from X11 to Wayland."
	echo "It seems that you are running the install script either under X11, or headless."
	echo "Either way, in both those cases, the autostart is done by adding to ~/.profile."
	echo "But if you later will use the default Pi GUI under Wayland,"
        echo "the PDP-10 will start without the type340 display. "
	echo "In which case: --> run this section of the install script again."
	echo
	echo "(negative comment on the manner in which Wayland breaks stuff removed)"
	echo "-------------------------------------------------------------------------------"
	echo
	case $yn in
		[Yy]* ) 
			echo testing for .profile or otherwise, .bash_profile
			if [ -f "$HOME/.profile" ]; then
				echo .profile found
				append_to_file "$HOME/.profile"

			elif [ -f "$HOME/.bash_profile" ]; then
				echo .bash_profile found
				append_to_file "$HOME/.bash_profile"
			else
				echo no .profile or .bash_profile found. Odd. Skipping autorun
			fi
			;;
		[Nn]* ) ;;
		* ) echo "Please answer yes or no.";;
	esac
#--- patch 20240501 part 2
#else
#	echo "cannot find either Wayland or X11, autostarting PiDP-10 skipped"
#---
fi

# ---------------------------
# install Teletype font
# ---------------------------
read -p "Install Teletype font? " yn
case $yn in
    [Yy]* ) 
        mkdir ~/.fonts
        cp /opt/pidp10/install/TELETYPE1945-1985.ttf ~/.fonts/
	fc-cache -v -f
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# Do you wish to add a DEC flavour to the desktop?
# ---------------------------
echo If you are not installing on a Pi, say No:
read -p "Add a DEC flavour to the Pi's desktop? " yn
case $yn in
	[Yy]* ) 
		# wall paper
		pcmanfm --set-wallpaper /opt/pidp10/install/turist.png --wallpaper-mode=fit
		# desktop files in Pi menu
		cp /opt/pidp10/install/desktop-files/* ~/.local/share/applications/
		# pdp view as icon on the desktop
		cp /opt/pidp10/install/desktop-files/*.desktop ~/Desktop/
		# let desktop icons run without annoying dialog box
		
		
		if [ -f "$HOME/.config/libfm/libfm.conf" ]; then
			sed -i 's/^quick_exec=.*/quick_exec=1/' ~/.config/libfm/libfm.conf
		else
			echo
			echo "-----------------------------------------------------------------------"
			echo "Note:"
		        echo " Double-clicking desktop icons on the Pi GUI always asks you"
			echo " 'if you want to execute this file'. To get rid of that annoyance"
			echo " go to the file manager's preferences and set"
			echo " Edit > Preferences > General > Don't ask options on launch executable"
			echo "-----------------------------------------------------------------------"
			echo
		fi	
		;;
	[Nn]* ) ;;
	* ) echo "Please answer yes or no.";;
esac


# ---------------------------
# reduce telnet unblock time
# ---------------------------
#echo If you are not installing on a Pi, say No:
#read -p "Reduce telnet release time? " yn
#case $yn in
#	[Yy]* ) 
#		sudo sysctl -w net.ipv4.tcp_fin_timeout=1
#		;;
#	[Nn]* ) ;;
#	* ) echo "Please answer yes or no.";;
#esac


echo
echo Done. Please reboot for all changes to take effect.
echo

