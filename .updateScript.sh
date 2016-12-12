#!/usr/bin/env bash
# Enable debugging by commenting out the following line
#set -x
#
# About: This little Shell-Script updates the TS3Monitor and all associated files - configs excluded
# Author: Sebastian Kraetzig <info@ts3-tools.info>
# Project: www.ts3-tools.info
# facebook: www.facebook.com/TS3Tools
#
# License: GNU GPLv3
#
# Donations: https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=7ZRXLSC2UBVWE
#

sleep 5s

# Get absolute path of script
cd "$(dirname $0)"

# Download latest version
wget --no-check-certificate -q https://github.com/TS3Tools/TS3Monitor/archive/master.zip

# Unzip latest version
if [[ $(unzip master.zip TS3Monitor-master/* -x TS3Monitor-master/configs/*) ]]; then
	if [ ! $(cp -Rf TS3Monitor-master/* . && rm -rf TS3Monitor-master/) ]; then
		rm -rf master.zip
		cd - > /dev/null
	        exit 1;
	fi
else
	rm -rf master.zip
	cd - > /dev/null
        exit 0;
fi
