

This is a working copy of my Burroughs B5500, Dec PDP6, KA10, KI10, KL10, KS10, SEL32, IBM 360
and IBM7000 series simulators for SimH.

# Stable released simulators.

# Dec PDP6

The PDP6 simulator is part of the KA/KI simulator. The PDP6 devices can be built into the KA10
simulator if desired.

The PDP6 runs TOPS 10 4.5 off Dectape.

  Disk  
  * 270 Disk  

  Tape  
  * 551 Tape  
  * 555 Dectape.  

  Paper Tape  
  * Punch  
  * Reader  

  Type 630 Terminal mux.  

  Type 340 graphics display.  

# Dec KA10 & KI10 & KL10 & KS10

The KA10 sim has successfully run Tops 10 4.5, 5.03 and 6.03, ITS and WAITS.  
The KI10 sim has successfully run Tops 10 6.03 with VMSER.  
The KL10 sim has successfully run Tops 10 6.03-7.03, ITS and Tops 20 V2-V7.  
The KS10 sim has successfully run Tops 10, Tops 20 and ITS.

   Disk   
   * RC10 RD10/RM10  
   * RP10 RP01/RP02/RP03  
   * RH10/RH20 RP04/RP06/RP07 (RP07 not supported under 6.03).   
   * RH10/RH20 RS04  
   * PMP (P. PETIT'S IBM CHANNEL)  
   * System Concepts DC-10 IBM 2314  

   Tape  
   * TM10A or B  
   * RH10/RH20 TM03/TU16  
   * TD10 Dectape  

   Paper Tape  
   * Punch  
   * Reader  
 
   * DC10E terminal mux.  
   * Morton tty Mux for ITS.  
   * Knight Kludge mux for ITS.  
   * Terminals on KL10 Front End.  
   * DZ11 on KS10.  

   * LP10 Line printer.  
   * LP20 Line printer on KL10 Front End, and KS10.  

   * IMP networking support for ITS and TENEX.  
   * NIA20 networking support for KL10.  
   * CH10 networking support for ITS.  
   * CH11 networking support for ITS (KS10).  
   * DUP11 networking support for KS10.  

   * 340 Display Station support.  
   * III Display support for WAITS.  

   * Optional support for PDP6 devices (standard if WAITS included).  

   The RP10 supports boot (actual hardware did not), by reading in Blocks 4-7
and transfering to the loaded value. RC10, RH10, TM10 support readin mode. 

   The KS10 supports RH11/RP and RH11/TM03 drives.

