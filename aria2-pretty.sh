#!/bin/bash

dir=$XDG_RUNTIME_DIR/aria2test
trap exit INT TERM
trap 'rm -rf -- "$dir"; pkill -P$$' EXIT
mkdir -p -- "$dir"

# TODO:
#   - add a human-formatted downloadSpeed and totalLength to the output
#   - add an ellipsized filename to the output
#   - implement and use rsleep() instead of sleep
#   - add colors to the output
#   - dynamically find an available port number for aria2's rpc
#   - randomly generate a secret for aria2's rpc

main()
{
	download "$@" &
	stty -echo -icanon time 0 min 0
	echo -ne '\e[s'
	while :; do
		setvars 'completedLength' 'totalLength' 'connections' 'downloadSpeed'
		[[ $totalLength -eq 0 ]] && continue
		percent=$(divide "$(( completedLength * 100 ))" "$totalLength" )
		echo -ne '\e[u\e[0J'
		printf '%s%% %d %d wat' "$percent" "$downloadSpeed" "$connections"
		sleep 0.05
	done &
	wait
}

# download a file using aria2
download()
{
	aria2c \
		'https://speed.hetzner.de/100MB.bin' \
		--quiet \
		--dir="$dir" \
		--enable-rpc \
		--rpc-listen-port=65432 \
		--rpc-secret='pacman' \
		"$@"
}

# set aria2's download attributes as shell variables
setvars()
{
	local string key value
	while IFS= read -r line; do
		string=${line#*\'}
		string=${string%\'*}
		case $line in
			*' Key:'*) key=$string value='' ;;
			*' Value:'*) value=$string ;;
			*) key='' value='' ;;
		esac
		[[ -n $key ]] && [[ -n $value ]] && printf -v "$key" '%s' "$value"
	done <<< "$(rpc "$@")"
}

# get the given active download attributes from aria2 using xmlrpc-c
rpc()
{
	set -- "${@/#/'s/'}"
	set -- "${@/%/,}"
	local IFS=''
	keys=$*
	keys=${keys%,}
	xmlrpc http://localhost:65432/rpc \
		aria2.tellActive 's/token\:pacman' "array/($keys)" \
		2>/dev/null
}

# return the division result of the two given integers to two decimal points
divide()
{
	local a=$1 b=$2 minlen=3
	local res=$(( a * 100 / b ))
	while [[ ${#res} -lt $minlen ]]; do
		res=0$res
	done
	echo "${res::-2}.${res:${#res}-2}"
}

main "$@"
