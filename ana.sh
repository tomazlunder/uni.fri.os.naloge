#!/bin/bash

LANG=en_US.UTF-8
stikalo_l=false
stikalo_n=false

#CvE NIMA ARGUMENTOV
if [ "$#" -eq 0 ]
then
	exit 1
fi

while [[ $1 = -* ]]; do
	case "$1" in
		-l )	#Stikalo l
			stikalo_l=true
			if ! [[ $2 =~ ^-?[0-9]+$ ]];then
				echo "Napaka: stikalu $1 mora slediti število." >&2
				exit 10
			else
				vrednost_l="$2"
			fi
			shift 2
			;;
		-n )	#Stikalo n
			stikalo_n=true
			if ! [[ $2 =~ ^-?[0-9]+$ ]];then
				echo "Napaka: stikalu $1 mora slediti število." >&2
				exit 10
			else
				vrednost_n="$2"
			fi
			shift 2
			;;
		-*) #Neznano stikalo
			echo "Napaka: neznano stikalo $1." >&2
			exit 10
			;;
	esac
done

#CE PO HANDLANJU STIKAL NIMA ARGUMENTOV
if [ "$#" -eq 0 ]
then
	exit 1
fi

#DATOTEKA
datoteka=$1
if  ! [ -e "$datoteka" ];
then
	(echo "Napaka: datoteka $datoteka ne obstaja." >&2)
	exit 1
fi

#Format brez stikal
format(){
while read line; do
	beseda=${line##* }
	case ${beseda//[[:alpha:]]} in 
		"")
		dolzina=${#beseda}
		st_pon=${line%% *}
		per=$(echo "scale=2; ($st_pon*100)/$st_b" | bc)
		echo "$st_pon $dolzina $beseda $per%"
	;;
	esac
done
}

#Format obe stikali
format_obe(){
while read line; do
	beseda=${line##* }
	case ${beseda//[[:alpha:]]} in 
		"")
		dolzina=${#beseda}
		st_pon=${line%% *}
		per=$(echo "scale=2; ($st_pon*100)/$st_b" | bc)
		if [ $dolzina -eq $vrednost_l ] && [ $st_pon -ge $vrednost_n ]; then
			echo "$st_pon $dolzina $beseda $per%"
		fi
	;;
	esac
done
}

#Format stikalo n
format_n(){
while read line; do
	beseda=${line##* }
	case ${beseda//[[:alpha:]]} in 
		"")
		dolzina=${#beseda}
		st_pon=${line%% *}
		per=$(echo "scale=2; ($st_pon*100)/$st_b" | bc)
		if [ $st_pon -ge $vrednost_n ]; then
			echo "$st_pon $dolzina $beseda $per%"
		fi
	;;
	esac
done
}

#Format stikalo l
format_l(){
while read line; do
	beseda=${line##* }
	case ${beseda//[[:alpha:]]} in 
		"")
		dolzina=${#beseda}
		st_pon=${line%% *}
		per=$(echo "scale=2; ($st_pon*100)/$st_b" | bc)
		if [ $dolzina -eq $vrednost_l ]; then
			echo "$st_pon $dolzina $beseda $per%"
		fi
	;;
	esac
done
}

#Stevilo besed
st_b=$(cat -s $datoteka | tr -d '[[:digit:].,:;"><!"»«]' | tr '[:upper:]' '[:lower:]' | tr '	' ' ' | wc -w)



#Brez stikal
if [ "$stikalo_l" = false ] && [ "$stikalo_n" = false ]; then
cat -s $datoteka | tr -d '[[:digit:].,:;"><!"»«]' | tr '[:upper:]' '[:lower:]' | tr '	' ' ' | tr ' ' '\n' |  sort | tr -s '\n' | uniq -c | sort -k1,1nr  | format  | tee | sort -k1,1nr -k2,2nr -k3,3 | cut -d " " -f 1,3,4
exit 0
fi
#Obe stikali
if [ "$stikalo_l" = true ] && [ "$stikalo_n" = true ]; then
cat -s $datoteka | tr -d '[[:digit:].,:;"><!"»«]' | tr '[:upper:]' '[:lower:]' | tr '	' ' ' | tr ' ' '\n' |  sort | tr -s '\n' | uniq -c | sort -k1,1nr  | format_obe  | tee | sort -k1,1nr -k2,2nr -k3,3 | cut -d " " -f 1,3,4
exit 0
fi
#Samo n
if [ "$stikalo_l" = false ] && [ "$stikalo_n" = true ]; then
cat -s $datoteka | tr -d '[[:digit:].,:;"><!"»«]' | tr '[:upper:]' '[:lower:]' | tr '	' ' ' | tr ' ' '\n' |  sort | tr -s '\n' | uniq -c | sort -k1,1nr  | format_n  | tee | sort -k1,1nr -k2,2nr -k3,3 | cut -d " " -f 1,3,4
exit 0
fi
#Samo l
if [ "$stikalo_l" = true ] && [ "$stikalo_n" = false ]; then
cat -s $datoteka | tr -d '[[:digit:].,:;"><!"»«]' | tr '[:upper:]' '[:lower:]' | tr '	' ' ' | tr ' ' '\n' |  sort | tr -s '\n' | uniq -c | sort -k1,1nr  | format_l  | tee | sort -k1,1nr -k2,2nr -k3,3 | cut -d " " -f 1,3,4
exit 0
fi
