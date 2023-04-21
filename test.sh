#!/bin/sh
dir=$(mktemp -d)
trap exit INT TERM
trap 'rm -rf -- "$dir"' EXIT
./aria2sh \
	'https://speed.hetzner.de/100MB.bin' 'https://speed.hetzner.de/100MB.bin' \
	--dir="$dir"
