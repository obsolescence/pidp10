As of 20251220:
- run install.sh's option to clone Cornwell's PIDP-10 repository,
  that will be cloned into src/pidp10. Note the 'i'.
  The old version stays untouched in src/pdp10 (note the lacking i!)

Then, we're going into the new src/pidp10/src/pdp10, 
*not* the old src/pdp10, to compile:

- cd opt/pidp10/src/pidp10/src/pdp10
- make PIDP10=1

That takes a good while, but when done, copy the new binaries to the 
/opt/pidp10/bin, from where they will be used from now on:

- cp BIN/p* /opt/pidp10/bin

For hysterical raisins, this needs to be done too:

- cp /opt/pidp10/bin/pdp10-ka /opt/pidp10/bin/pidp10

And finally:
- run the first option (set priorities) in install.sh to give 
  GPIO rights to the new binaries
  (If you forget this, your Blinkenlights will flicker, 
  even if they are not supposed to)
