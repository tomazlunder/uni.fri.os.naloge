#!/bin/bash
if [ $# -eq 0 ];then
	echo "Podajte argument"
	exit 1
fi

if [ $# -gt 1 ];then
	echo "St. arg. mora biti 1"
	exit $#
fi

Orgstring=$1
Org=$Orgstring
Len=${#Orgstring}

if [ $Len -eq 1 ];then
	echo "Argument mora biti daljsi od le enega znaka"
	exit 255
fi

Newstring=""
for ((i=0; i<=$Len; i++)); do
	Newstring=${Orgstring:i:1}$Newstring
done

if [ $Orgstring = $Newstring ];then
	echo "$Org JE palindrom"
	exit 0
else
	echo "$Org NI palindrom"
	exit 0

fi


