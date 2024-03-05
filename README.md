![image](https://user-images.githubusercontent.com/7725197/209851202-7e9bab6d-1ec1-4161-99de-54106cb87166.png)

# Github repository for the PiDP-10 project

Work in progress, supporting the PiDP-10 replica. 
As of March 2024, this is in beta stage for the first 50 daring builders (thank you for helping in the beta phase). The code will change rapidly this month, then be out of beta in April.

Main web sites:

https://obsolescence.dev/pidp10
- Overview & context

https://obsolescence.wixsite.com/obsolescence/pidp10
- Details on how to build & use


## 0. What is this?

The PiDP-10 is a replica of the PDP-10 'mainframe' complete with glorious Blinkenlights. 

Inside sits a Raspberry Pi with two concurrent hearts beating: a virtualised PDP-10 and a physical Linux.  
One core may be virtual rather than silicon, but no matter.

The world inside the PiDP-10 is not just a PDP-10, but the entire MIT AI Lab (of myth and lore) consisting of dozens of interlinked computers and other hardware. It normally runs the ITS operating system, with hundreds of MIT software projects recovered from MIT tape archives. You can also boot into TOPS-10, DEC's own operating system, with its own storied history.

**The mythology, some introductory links**
https://en.wikipedia.org/wiki/PDP-10  
https://en.wikipedia.org/wiki/MIT_Computer_Science_and_Artificial_Intelligence_Laboratory#LCS_and_AI_Lab  
https://en.wikipedia.org/wiki/Hackers:_Heroes_of_the_Computer_Revolution , intro chapters online here: https://www.gutenberg.org/cache/epub/729/pg729.html  
https://en.wikipedia.org/wiki/Hacker_ethic  
._
https://github.com/PDP-10/its

![image](https://user-images.githubusercontent.com/7725197/209852125-55c81735-f8c0-4956-8ba1-e912d53338ec.png)

## 1. How? Quick install & lookaround

    cd /opt # (needs to be installed here)
    sudo git clone https://github.com/obsolescence/pidp10.git
    /opt/pidp10/install/install.sh

Questions that the install script asks you:

-Set required access privileges to pidp10 simulator?
	Makes /opt/pidp10 owned by user pi, gives simulator program GPIO access permissions
-Install required dependencies for running the PiDP-10?
    Installs required libraries for precompiled binary
-Install add'l dependencies for compiling the source code?
	Installs other libraries needed for recompilation
-Let raspi-config enable i2c, VNC?
	Optional, not needed
-Automatically start the PiDP-10 core when logging in?
	Optional, not needed, adds pidp10 to .profile
-Copy control script links (pdpcontrol, pdp) to /usr/local/bin?
	Optional, but required for user comfort
-Do you wish to download ITS project source code?
	Optional, it clones Lars Brinkhoff's github and the many it ties in to
-Download and install required disk images?
	Gets ITS and TOPS-10 installed, without you only have a Blinky demo
-Install Teletype font?
	Required for the Teletype Model 33 simulator
-Add optional DEC flavoured wallpaper?
	Optional


## 2. More: Full install and explaining the setup

Keep in mind, this repository is really for the PiDP-10 - or a regular Raspberry Pi (4 or 5 recommended). If all you have is a Linux PC, you should use the original ITS repository ().

Explanation: there's lots of software next to the PDP-10 engine itself. Around that are binaries to simulate various hooked-up hardware from the MIT AI lab: some PDP-11s, a PDP-6, other computers, terminals, etc. These are 'the binaries' and this is the hardware farm that becomes your playground. Not everything has to run on the PiDP-10 itself.

It is quite normal to have your terminal simulator (etc, etc) run on your laptop, logging in to the PiDP-10 remotely. And you might invite others for a  multiplayer Mazewar session, each connecting to the PiDP-10 from their own location. So binaries for Intel linux will be added soon to this distribution, at the moment use the original ITS repository to generate their binaries. 


## 3. Command & Control your hardware lab

The tools below assume that you ran the install script. There are then two command line scripts, the install script puts links in /usr/local/bin:

- **pdpcontrol**: power up/power down the PDP-10 itself

`pidpcontrol start` starts the PDP-10 engine in the background, wrapped in a 'screen' session; `pidpcontrol stop` kills the PDP-10. Do make sure you have shut down any operating system on the PDP-10 before. This is a power switch, not a shutdown command. `pidpcontrol stat` and `pidpcontrol stat` tell you whether the PDP-10 is up or not.

- **pdp**: monitor the PDP-10 engine

`pdp` will get you into the 'screen' session that contains the PDP-10 engine. This is seldomly necessary, but it allows you to set the simh settings interactively. You can close the screen session if you started it from the command line with "Ctrl-A, d". If run from the GUI, just close the window.
`pdp -h` will show you how it can start all the various terminals and devices. `pdp con` gets you to the Teletype Model 33 simulator for instance, needed for the ITS boot process.

Please note that `pdpcontrol` and `pdp` interact with the PDP-10 engine, but are not part of it. They are just scripts in /opt/pidp10/bin. You can run and close them as you see fit. The PDP-10 just runs.


## 4. Exploring the AI Labs playground

**Choice of terminals from pdpanel:**

You have a choice of VT-05, VT-52, Datapoint 3300, Imlac, Knight TV or regular telnet as regular terminals. The operator console is either a simulated Teletype (`pdp con` with Teletype noise) or simple telnet (`pdp telcon` with peace and quiet) to log in to the PDP-10. The operator's console is used to control the PDP-10 but not really for normal users.

The Knight TV-11 is available too, which consists of two parts. First, a PDP-11/20 computer which has its memory mapped into the PDP-10, allowing a great number of concurrent graphics terminals to connect. You first have to boot up the TV-11 and then you can start up any number of the little Knight TV terminals. The tv11 simulator is called `tv11` unsurprisingly, and it is already fired up by the simh ITS boot script. The TV-11 can be hacked nicely from the PDP-10 side as well as from the Knight TV terminals, it has its own Teletype attached.

The GT40 is a PDP-11 with vector/pixel display, which also has some special software for it on ITS. Of course, it can also run as its own PDP-11 if you wish. To play Lunar Lander. The Tektronix 4010 is an amazing terminal too, with the highest resolution graphics of them all.

Important: you can run all these terminal sessions from other computers, not just the Pi. the PDP-10 thinks of the above as somehow wired into itself. But the wiring is implemented virtually, over telnet. Which means that you should not limit yourself to running these terminal simulations on the PiDP itself. Just use a mix of laptops to connect up. Binaries are available for regular Raspberry Pi's and PC Linux. It would not be a problem to get them to run in Windows as well.


**Other connected hardware:**

The old PDP-6 is connected to the PDP-10 through shared memory. It can be used as a separate CPU, controlled from ITS on the PDP-10. Its real purpose in life is to play its own version of spacewar, so as to leave the PDP-10 free for non-gamers. The PDP-6 front panel is simulated on-screen, and of course it has its own Teletypes attached to it. Next to spacewar, there are some other tasks it can perform as well. 

The IMP sits hidden in the background and gives you access to the internet, which seems to have grown out of Arpanet whilst we were not looking. Chaosnet is another network to hook up many local computers. Worth investigating. These days, there is such a thing as a Global Chaosnet. 

The Type 340 display is wedded to the PDP-10, it must run on the same machine as the PDP-10 engine. The Type 340 is the pretty way of looking at a PDP-10. The system monitor (Peek) can use it, spacewar runs on it, and lots of other software as well. Think of it as the second display on your PDP-10 (although it comes with its own simulated keyboard and light pen).


**Source code and hacking about**
Assuming you let the installer run though all its options, you will find nearly a dozen software projects (the PDP-10, the terminals, the hooked-up other computers from the AI Lab). Edit-compile-run, and install your enhanced binaries in /opt/pidp10 once you are satisfied. Note that almost all these tools are projects stored here as live git submodules.
`pidp10/src/panama5`: source code for a modified Richard Cornwell's PDP-10 simulator. Use make X86=1 if you do not have a PiDP-10 front panel, it will run fine. 
	The Panama5 version is temporary, Richard wants to roll the front panel driver back into his original PDP-10/KA10 github at https://github.com/rcornwell/sims
`pidp10/src/its`: the heart of the ITS beast. 
`pidp10/src/its/tools` you will find the peripheral projects.
`pidp10/src/sty`: a Teletype Model 33simulator with satisfying noises. But it is a quick hack, we had finish this in a hurry. Still, works fine.


# Credit where credit is due
I only wrapped up other people's genius into a physical front panel. There is a whole community behind this body of code. So as not to leave anyone short, I will only mention three people here: Richard Cornwell wrote the PDP-10 KA10 simulator (the Engine) and Lars Brinkhoff revived ITS and all the peripheral hardware, to make this a Hacker Playground. Angelo Papenhoff added the PDP-6 and many other elements to this. Which leaves me to emphasize that I am only the Master of Plastics, giving this a physical form factor in the PiDP-10. That is not where the genius lies, and it is also not where the hours of hard work were spent. This builds on a community of dozens.
