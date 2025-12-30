#!/bin/sh -e

if [ "$1" = sub ]; then
	pid="$2"
	( echo testwort | xtightvncviewer -autopass 127.0.0.1:4 || true; \
							kill -s TERM "$pid" ) &
else
	# used to be 192.168.1.15
	exec ssh -L 5904:127.0.0.1:5900 \
			-o permitlocalcommand=yes -o LocalCommand="$0 sub $$" \
			linux-fan@192.168.1.22 /usr/bin/tail -f /dev/null
fi
