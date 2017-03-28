#!/bin/bash

run() {
	while true; do
		read_pipe
		pregledaj_vpise
		sleep 0.1
	done
}

read_pipe() {
	koncaj=false
	#echo "[P] Berem pipe..." #DEBUG
	if read -t 0.01 line <>$pipe; then
		
		#echo "1. Vstopil v pipe" #DEBUG
		IFS=':' read -ra PARGS <<< "$line"
		if [[ "${PARGS[0]}" == "proc" ]] && [[ "${PARGS[2]}" != "" ]]; then
			echo "1.1 PROC" #DEBUG
			n=${PARGS[1]}			

			IFS=',' read -ra OBSTOJECI <<< "${PARGS[2]}"
			
			temp=$(ps ${OBSTOJECI[0]} | tail -n 1 | xargs | cut -d" " -f5-)
			temp=${temp#}

			#echo "1.2 Temp = $temp, CTemp = ${temp:0:9}" #DEBUG

			if [[ "${temp:0:9}" == "/bin/bash" ]]; then
				#echo "1.3 Tip: SKRIPTA"
				canon_p0=$temp
				enaki=true 
			else
				#echo "1.3 Tip: NAVADEN" #DEBUG
				temp1=$(which $temp)
				
				if [[ $(echo "$temp" | wc -w) -gt 1 ]];then
					temp=${temp#* }
					canon_p0="$temp1 $temp"
				else
					canon_p0="$temp1"
				fi
				enaki=true
			fi

			echo "1.4 Canon_p0 = $canon_p0" #DEBUG

			for key in "${!PIDS[@]}"; do
				if [[ "$key" == "$canon_p0" ]];then
					echo "Run configuration already exists." >&2
				fi
			done

			for x in "${OBSTOJECI[@]}"; do
				if [ -e /proc/$x ]; then
					temp=$(ps $x | tail -n 1 | xargs | cut -d" " -f5-)
					if [[ "${temp:0:9}" == "/bin/bash" ]]; then
						canon_px=$temp 
					else
						temp1=$(which $temp)
						if [[ $(echo "$temp" | wc -w) -gt 1 ]];then
							temp=${temp#* }
							canon_px="$temp1 $temp"
						else
							canon_px="$temp1"
						fi
					fi

					if [[ "$canon_p0" != "$canon_px" ]]; then
						enaki=false
						break
					fi
				else
					enaki=false
					break
				fi
			done

			echo "1.5 Vse vredu:$enaki" #DEBUG
			if [[ "$enaki" == true ]]; then
				NUM[$canon_p0]="${PARGS[1]}" #Št. instanc
				LASTCHECK[$canon_p0]=0

				string=""
				for x in "${OBSTOJECI[@]}"; do
					string="$string:$x"
				done
				string=${string:1}
				PIDS["$canon_p0"]=$string #Pidji v formatu.. pid1:pid2: .. :pidn
				canon_last=$canon_p0
				echo "1.6 Dodano vodenje: $canon_p0" #DEBUG
			else
				echo "PID matching error: ${PARGS[2]}" >&2 #DEBUG
			fi
			#echo "End proc" #DEBUG
		fi

		if [[ "${PARGS[0]}" == "stop" ]]; then
			key=${PARGS[1]}
			unset PIDS["$key"]
			unset NUM["$key"]
			unset LASTCHECK["$key"]	
		fi

		if [[ "${PARGS[0]}" == "log" ]]; then
			log_all	
		fi

		if [[ "${PARGS[0]}" == "log last" ]]; then
			log_last	
		fi

		if [[ "${PARGS[0]}" == "exit" ]]; then
			for key_a in "${!PIDS[@]}"; do
				IFS=':' read -ra VALUES <<< "${PIDS[$key_a]}"
				for x in "${VALUES[@]}"; do
					kill -SIGTERM $x
				done
			done
			exit 0
		fi		
	fi
}


pregledaj_vpise() {
	#echo "[G]Gledam vpise ..." #DEBUG
	for key_a in "${!PIDS[@]}"; do
		zadnjic="${LASTCHECK[$key_a]}"
		zdaj=$(echo "$(date +%s) - $interval" | bc)
		if (( $(echo "$zdaj >= $zadnjic" | bc -l) )); then 
			
			LASTCHECK[$key_a]=$(date +%s)
			num_a="${NUM[$key_a]}"
			value_a="${PIDS[$key_a]}"
			#echo "* Process: $key_a | Required: $num_a | Pids: $value_a" #DEBUG
			IFS=':' read -ra VALUES <<< "$value_a"
			value_a=""
			for x in "${VALUES[@]}"; do
				enaki=true
				temp=$(ps $x | tail -n 1 | xargs | cut -d" " -f5-)
				if [[ "${temp:0:9}" == "/bin/bash" ]]; then
					canon_px=$temp 
				else
					temp1=$(which $temp)
					if [[ $(echo "$temp" | wc -w) -gt 1 ]];then
						temp=${temp#* }
						canon_px="$temp1 $temp"
					else
						canon_px="$temp1"
					fi
				fi

				if [[ "$key_a" != "$canon_px" ]]; then
					enaki=false
				fi
				if [[ "$enaki" == true ]]; then
					value_a="$value_a:$x"
				fi
			done
		

			value_a=${value_a:1}
			unset VALUES
			IFS=':' read -ra VALUES <<< "$value_a"

			#echo "Cilj: $num_a, trenutno: ${#VALUES[@]}" #DEBUG
			if [[ "$num_a" -gt "${#VALUES[@]}" ]]; then
				eval "$key_a &"
				#echo "Zagnal $key_a"
				new_pid=$!
				value_a="$value_a:$new_pid"
			fi
			PIDS[$key_a]=$value_a
		fi
	done
	#echo " ... pregledal"
}

log_all() {
	if ! [ -e active.log ]; then
		touch active.log
	else
		rm active.log
		touch active.log
	fi
	
	echo $(date +%s%3N) > active.log
	if [[ "${#PIDS[@]}" -gt 0 ]]; then 
		for key_a in "${!PIDS[@]}"; do
			value_a="${PIDS[$key_a]}"
			echo "$key_a" >> active.log
			echo $(echo $value_a | tr ":" " ") >> active.log
		done
	fi
}

log_last() {
	if ! [ -e active.log ]; then
		touch active.log
	else
		rm active.log
		touch active.log
	fi

	echo $(date +%s%3N) > active.log
	value_l="${PIDS[$canon_last]}"
	echo "$canon_last" >> active.log
	echo $(echo $value_l | tr ":" " ") >> active.log
}




#Pregled argumentov
if [[ "$#" -ne "2" ]]; then
	echo "Napacno stevilo argumentov" >&2
	exit 1
fi


#if [[ "$1" -lt "0" ]]; then #Dodelaj
#	echo "Prvi argument mora biti pozitivno število"
#	exit 1
#fi

if [[ ! -p "$2" ]]; then
	echo "No such pipe" >&2
	exit 1
fi

interval=$1
#echo "interval: $interval"
pipe=$2
za_primerjat=""
canon_last=""
declare -A PIDS=()
declare -A NUM=()
declare -A LASTCHECK=()

run
exit 0
