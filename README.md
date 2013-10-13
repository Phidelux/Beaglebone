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

## License

Copyright (c) 2013 Andreas Wilhelm <info@avedo.net>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

