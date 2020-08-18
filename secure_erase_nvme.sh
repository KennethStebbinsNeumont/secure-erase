#!/bin/bash

DRIVE=$1

if [ "$DRIVE" == "" ]; then
	DRIVE="/dev/nvme0n1"
fi

RESPONSE=$(nvme list | grep $DRIVE)
if [ "$RESPONSE" == "" ]; then
	echo "Drive $DRIVE was not found" 1>&2
	exit 1
fi

echo 'Formatting drive...'
RESPONSE=$(nvme format $DRIVE --ses=1 2>&1 1>/dev/null)

if [[ $? -eq 0 && "$RESPONSE" == "" ]]; then
	echo "Format successful"
	echo $RESPONSE
else	
	echo $DRIVE appears frozen. Attempting to unfreeze by sleeping and waking the machine...
	sleep 2
	# Load a few applications into memory, since the flash
	# drive normally fails to mount after resuming from sleep
	fdisk --help 1>/dev/null
	shutdown --help 1>/dev/null
	mount --help 1>/dev/null
	# Put the machine to sleep and wake it up within 15 seconds
	rtcwake -m mem -s 15 1>/dev/null
	echo Attepting to format...
	RESPONSE=$(nvme format $DRIVE --ses=1 2>&1 1>/dev/null)
	if [[ $? -eq 0 && "$RESPONSE" == "" ]]; then
		echo $RESPONSE
		echo "Unfreezing attempt failed." 1>&2
		exit -1
	else
		echo "Format successful"
	fi
fi

echo 'Creating a new partition table with fdisk...'
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $DRIVE 1>/dev/null
	g
	w
EOF

echo 'Done!'

while true; do
	read -p 'Do you want to shutdown now? (Y/n): ' uresponse

	if [ "$uresponse" == "y" ] || [ "$uresponse" == "Y" ]; then
		echo 'Shutting down...'
		shutdown now	
		break
	elif [ "$uresponse" == "n" ] || [ "$uresponse" == "N" ]; then
		break
	else
		echo "Unrecognized response $uresponse"
	fi

done
