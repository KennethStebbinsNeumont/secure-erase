#!/bin/bash

DRIVE=$1

if [ "$DRIVE" == "" ]; then
	DRIVE="/dev/sda"
fi

echo Testing whether $DRIVE is frozen...

RESPONSE=$(hdparm -I $DRIVE | grep frozen)


if [ "$RESPONSE" == "	not	frozen" ]
then
	echo $DRIVE is not frozen
elif [ "$RESPONSE" == "		frozen" ]
then
	echo $DRIVE is frozen. Attempting to unfreeze by sleeping and waking machine...
	fdisk --help 1>/dev/null
	shutdown --help 1>/dev/null
	mount --help 1>/dev/null
	rtcwake -m mem -s 15 1>/dev/null
	RESPONSE=$(hdparm -I $DRIVE | grep frozen)
	if [ "$RESPONSE" == "		frozen" ]; then
		echo Unfreezing attempt failed.
		exit -1
	else
		echo Unfreezing successful.
	fi
else
	echo Unable to determine whether $DRIVE is frozen.
	exit -1
fi

echo Attempting to securely erase drive...
hdparm --user-master u --security-set-pass p $DRIVE 1>/dev/null
hdparm --user-master u --security-erase-enhanced p $DRIVE 1>/dev/null
#hdparm --user-master u --security-disable p $DRIVE 1>/dev/null


echo Creating a new GPT partition table...
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

