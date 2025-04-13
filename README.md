# PIC10F320 Shower Timer

A simple shower timer which useful for a high-traffic bathrooms. The timer starts
with 5 minutes and a button can be pressed to add more minutes. When the timer goes
to zero, an alarm will go off which can be silenced by pressing the button. To
restart the timer, reset the device.

## Build and Run

To build this application, use MPLAB X IDE.

## Circuit

A shift register, [74AHC595](https://www.ti.com/lit/ds/symlink/sn74ahc595.pdf)
in this case, is connected to the three output pins of the PIC10F320. They are
connected as follows:

* `RA0` connects to `SER`
* `RA1` connects to `RCLK`
* `RA2` connects to `SRCLK`

TODO: Describe the dual shift registers
