# Beaglebone

This repository contains different scripts and code samples for the Beaglebone and the Beaglebone Black.

## arch4bone.sh

The arch4bone.sh script could be used to flash Arch Linux to a Beaglebone, Beaglebone Black or even the Beaglebone Black internal eMMC rom.

**Usage**: arch4bone.sh [-hvm] [-d <device>] [-b <board>]

*-h|--help*:  
    Displays this help.  
*-v|--version*:  
    Displays the current version of this script.  
*-b|--board*:  
    Sets the name of the board you would like to flash.  
    Should be one of "bone" for the Beaglebone or  
    "black" for the Beaglebone Black.  
*-d|--device*:  
    Sets the name of the device to which Arch Linux  
    should be flashed to (/dev/sdX).  
*-m|--mmc*:  
    Parameter should be used to flash Arch Linux  
    to a Beaglebone Black eMMC rom.



