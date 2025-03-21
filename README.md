# PIC10F320 Shower Timer

TODO: Describe the shower timer's purpose

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
