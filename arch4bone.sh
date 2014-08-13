#! /bin/sh
set -euo pipefail
IFS=$'\n\t'

# Copyright (c) 2013 Andreas Wilhelm <info@avedo.net>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Define the usage text.
USAGE=$( cat <<EOF
Usage: `basename $0` [-hvm] [-d <device>] [-b <board>]\n
-h|--help:
\tDisplays this help.
-v|--version
\tDisplays the current version of this script.
-b|--board
\tSets the name of the board you would like to flash.
\tShould be one of "bone" for the Beaglebone or
\t"black" for the Beaglebone Black.
-d|--device
\tSets the name of the device to which Arch Linux 
\tshould be flashed to (/dev/sdX).
-m|--mmc
\tParameter should be used to flash Arch Linux 
\tto a Beaglebone Black eMMC rom.
EOF
)

# All users with $UID 0 have root privileges.
ROOT_UID=0

# Just one single user is called root.
ROOT_NAME="root"

# Definition of error functions.
function info()
{
   echo -e "$*" >&2
   exit 0
}

function warning()
{
   echo -e "$*" >&2
}

function error()
{
   echo -e "$*" >&2
   exit 1
}

function yesno()
{
   local ans
   local ok=0
   local default
   local t

   while [[ "$1" ]]
   do
      case "$1" in
      --default)
         shift
         default=$1
         if [[ ! "$default" ]]; then 
            error "Missing default value"
         fi

         t=$(tr '[:upper:]' '[:lower:]' <<<$default)

         if [[ "$t" != 'y'  &&  "$t" != 'yes'  &&  "$t" != 'n'  &&  "$t" != 'no' ]]; then
            error "Illegal default answer: $default"
         fi
         default=$t
         shift
         ;;
      -*)
         error "Unrecognized option: $1"
         ;;
      *)
         break
         ;;
      esac
   done

   if [[ ! "$*" ]]; then 
      error "Missing question"
   fi

   while [[ $ok -eq 0 ]]
   do
      read -p "$*" ans
      if [[ ! "$ans" ]]; then
         ans=$default
      else
         ans=$(tr '[:upper:]' '[:lower:]' <<<$ans)
      fi 

      if [[ "$ans" == 'y'  ||  "$ans" == 'yes'  ||  "$ans" == 'n'  ||  "$ans" == 'no' ]]; then
         ok=1
      fi

      if [[ $ok -eq 0 ]]; then 
         warning "Valid answers are: yes/no"
      fi
   done
   
   [[ "$ans" = "y" || "$ans" == "yes" ]]
}

function cleanUp() 
{
	rm -rf /tmp/bone/
}

# Check if user has root privileges.
if [[ $EUID -ne $ROOT_UID ]]; then
   error "This script must be run as root!"
fi

# Check if user is root and does not use sudoer privileges.
if [[ "${SUDO_USER:-$(whoami)}" != "$ROOT_NAME" ]]; then
   error "This script must be run as root, not as sudo user!"
fi

# Setup script vars.
devices=$(cat /proc/partitions|awk '/^ / {print "/dev/"$4}')
device=""
board=""
mmc=0

# Fetch command line options.
while [[ -n "${1+xxx}" ]]
do
   case "$1" in
      --help|-h)
         info "$USAGE"
         ;;
      --version|-v)
         info "`basename $0` version 1.0"
         ;;
      --device|-d)
         shift
         device=$1
         
         if [[ ! "$device" ]]; then 
            error "Missing device name!\n\n$USAGE"
         fi

         device=$(tr '[:upper:]' '[:lower:]' <<< $device)
         
         if [[ ! -b $device ]]; then
            error "Device $device is not a block device!\n\n" \
            	"\rFollowing devices are available:\n" \
            	"\r$devices\n"
         fi
         
         shift
         ;;
      --board|-b)
         shift
         board=$1
         if [[ ! "$board" ]]; then 
            error "Missing board name!"
         fi

         board=$(tr '[:upper:]' '[:lower:]' <<< $board)

         if [[ "$board" != "bone"  &&  "$board" != "black" ]]; then
            error "Invalid board name ($board)!\n\n$USAGE"
         fi
      	
         shift
      	;;
      --mmc|-m)
         mmc=1
         shift
         ;;
      -*)
         error "Unrecognized option: $1\n\n$USAGE"
         ;;
      *)
         break
         ;;
   esac
done

if [[ $mmc -eq 1 ]]; then
   device="/dev/mmcblk1"
fi

if [[ ! "$device" ]]; then 
   error "Missing device name!\n\n$USAGE"
fi

if ! command -v parted >/dev/null 2>&1 ; then
   error "Parted required, but not installed. Aborting."
fi

if ! yesno --default no "Are you sure you would like to wipe $device (default no) ? "; then
   info "Aborting."
fi

# Unmount all partitions in /dev/sdX.
for partition in $(parted -s $device print|awk '/^ / {print $1}')
do
	if [[ $(mount | grep $partition) != "" ]]; then
	   echo "Unmounting partition ${device}${partition} ..."
	   umount "${device}${partition}"
	fi
done

# Generate the names of first and second partition.
if [[ $mmc -eq 1 ]]; then
   part1="/dev/mmcblk1p1"
   part2="/dev/mmcblk1p2"
else 
   part1="${device}1"
   part2="${device}2"
fi

# Create a temporary directory within /tmp.
mkdir -p /tmp/bone

# Run this block only if an sd card is flashed.
if [[ $mmc -ne 1 ]]; then
	# Remove each partition in /dev/sdX.
	for partition in $(parted -s $device print|awk '/^ / {print $1}')
	do
		echo "Removing partition ${device}${partition} ..."
		parted -s $device rm ${partition}
	done

	# Find size of the entire /dev/sdX disk.
	v_disk=$(parted -s $device print|awk '/^Disk/ {print $3}'|sed 's/[Mm][Bb]//')

	# Important user output!
	echo "Setting up boot partition $part1 ..."

	# Create the first partition as a primary fat16 partition of 64 MB beginning at first sector ...
	parted -s $device mkpart primary 0 64

	# ... and enable the boot flag on this partition.
	parted -s $device set 1 boot on

	# Important user output!
	echo "Setting up root partition $part2 ..."

	# Create the second partition as a primary ext4 partition using the left space.
	parted -s $device mkpart primary 64 ${v_disk}
fi

# Important user output!
echo "Creating fat16 boot partition filesystem ..."
echo "Creating ext4 root partition filesystem ..."

# Create the fat16 filesystem at the first partition ...
mkfs.vfat -F 16 $part1

# ... and the ext4 filesystem at the second partition.
mkfs.ext4 $part2

# Print out the new partition table.
parted $device print

# Download the beaglebone bootloader tarball, ...
wget http://archlinuxarm.org/os/omap/BeagleBone-bootloader.tar.gz --directory-prefix=/tmp/bone

# ... create a new directory "boot", ...
mkdir -p /tmp/bone/boot

# ... mount this directory to the first partition, ...
mount $part1 /tmp/bone/boot

# ... extract the bootloader tarball here ...
tar -xvf /tmp/bone/BeagleBone-bootloader.tar.gz -C /tmp/bone/boot

# ... and unmount the partition.
umount /tmp/bone/boot

# Download the beaglebone root filesystem tarball, ...
wget http://archlinuxarm.org/os/ArchLinuxARM-am33x-latest.tar.gz --directory-prefix=/tmp/bone

# ... create a new directory "root", ...
mkdir -p /tmp/bone/root

# ... mount this directory to the second partition, ...
mount $part2 /tmp/bone/root

# ... extract the root filesystem tarball here ...
tar -xf /tmp/bone/ArchLinuxARM-am33x-latest.tar.gz -C /tmp/bone/root

# ... and unmount the partition.
umount /tmp/bone/root

# Do some clean up!
cleanUp

# Done! Print out some information to the user.
echo "Done!"
