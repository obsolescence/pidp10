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


read -p "Set required access privileges to pidp10 simulator? " yn
case $yn in
    [Yy]* )
	    # make sure that the directory does not have root ownership
	    # (in case the user did a simple git clone instead of 
	    #  sudo -u pi git clone...)
	    myusername=$(whoami)
	    mygroupname=$(id |sed -e "s|.*gid=[0-9]*(||g" -e "s|).*||")
	    sudo chown -R $myusername:$mygroupname /opt/pidp10
	    # make sure pidp10 simulator has the right privileges
	    # to access GPIO with root privileges:
	    sudo chmod +s /opt/pidp10/bin/pidp10
	    # to run a RT thread:
	    sudo setcap cap_sys_nice+ep /opt/pidp10/bin/pidp10
	    ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


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
	#the Pi does not come with telnet installed, so --
        sudo apt-get install -y telnet
        sudo apt-get install -y telnetd
	# for pdpcontrol: 
	sudo apt-get -y install expect
        # Install screen
        sudo apt-get install -y screen
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


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
	sudo apt install -y libx11-dev libxt-libxft-dev
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
read -p "Automatically start the PiDP-10 core when logging in? " yn
case $yn in
    [Yy]* ) 
        # first, make backup copy of .bashrc...
        test ! -f ~/profile.backup && cp -p ~/.profile ~/profile.backup
        # add the line to .profile if not there yet
        if grep -xq "pdpcontrol start 0" ~/.profile
        then
            echo .profile modification already done, OK.
        else
            sed -e "\$apdpcontrol start" -i ~/.profile
        fi
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


# ---------------------------
# Copy control scripts (pdpcontrol, pdp) to /usr/local/bin?
# ---------------------------
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
# install Lars Brinkhoff's full ITS project
# ---------------------------
read -p "Do you wish to download ITS project source code? " yn
case $yn in
    [Yy]* ) 
        cd /opt/pidp10/src
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
# install PDP-10 disk images
# ---------------------------
read -p "Download and install required disk images? " yn
case $yn in
    [Yy]* ) 
        echo -----------------------
        echo Downloading PDP-10 ITS disk images
        wget -P /opt/pidp10/systems/its https://pidp.net/pidp10-sw/its-system.zip
	unzip -d /opt/pidp10/systems/its /opt/pidp10/systems/its/its-system.zip
        echo -----------------------
        echo Downloading PDP-10 TOPS-10 disk images
        wget -P /opt/pidp10/systems/tops10-603 https://pidp.net/pidp10-sw/tops603ka.zip
        unzip -d /opt/pidp10/systems/tops10-603 /opt/pidp10/systems/tops10-603/tops603ka.zip
        echo -----------------------
        ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac


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
read -p "Add optional DEC flavoured wallpaper? " yn
case $yn in
    [Yy]* ) 
        # wall paper
        pcmanfm --set-wallpaper /opt/pidp10/install/turist.png --wallpaper-mode=fit

            ;;
    [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
esac

echo
echo Done.
echo

