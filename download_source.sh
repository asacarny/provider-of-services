#!/bin/bash

# download files from these years.
STARTYEAR=1993
ENDYEAR=2017

# choose method wget or rsync (requires NBER username)
METHOD="rsync"

if [ "$METHOD" == "rsync" ]
then
	echo "Please enter your NBER username"
	read nber_username
elif [ "$METHOD" == "wget" ]
then
	echo "Using wget"
else
	echo "invalid method"
	exit
fi

mkdir -p source/

for ((year=$STARTYEAR; year <= $ENDYEAR; year++))
do
	echo "downloading reports for $year"

	if [ "$METHOD" == "wget" ]
	then
		wget http://www.nber.org/pos/${year}/pos${year}.dta.zip \
			-O source/pos${year}.dta.zip
		unzip source/pos${year}.dta.zip -d source/
		rm source/pos${year}.dta.zip
	elif [ "$METHOD" == "rsync" ]
	then
		rsync --progress -z \
			${nber_username}@nber4.nber.org:/home/data/pos/${year}/pos${year}.dta \
			source/pos${year}.dta
	else
		echo "invalid method"
		exit
	fi

done
