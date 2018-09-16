#!/bin/bash
#
# Author: Milan Pässler <me@pbb.lc>
# Author: Finn Behrens <finn@dsgvo.fail>
#
# Rifo is a minimalist application launcher for swaywm
# RifoPass is a minimalist pass view for i3
#
# Requirements: termite fzf jq pass
#

passlistgen()
{
	shopt -s nullglob globstar
	prefix=${PASSWORD_STORE_DIR-~/.password-store}
	password_files=( "$prefix"/**/*.gpg )
	password_files=( "${password_files[@]%.gpg}" )
	password_files=( "${password_files[@]#"$prefix"/}" )
	printf '%s\n' "${password_files[@]}"
	shopt -u nullglob globstar
}

decodeName()
{
	if [ $(echo $1 | head -1) = '/' ] & [ -e $1 ]; then
		echo $1
	else 
		file=$HOME/$1
		if [ -e $file ]; then 
			echo $file
		else
			exit 1
		fi
	fi
}

CACHE=$HOME/.local/share/rifopass-cache

#
# Code starts here
#

args=foo

if [ $1 = "fill-in" ]; then
	args=fill_in
	shift
fi

if [ -z "$1" ]
then
	termite --title="rifopass" --exec="bash -c '$(decodeName $0) $args > /tmp/rifopass-command'"
# run the application
bash -c /tmp/rifopass-command
rm /tmp/rifopass-command
exit 0
fi

# make sure the cache file exists
touch "$CACHE"

# join together the full list of commands and cache file
LIST=$(join -a2 <(sort "$CACHE") <( ( passlistgen | sed 's/ /_/g') | sort -u) | sort -Vr -k2 | cut -d' ' -f1)

# fzf prompt
SEL=$(echo "$LIST" | sed 's/_/ /g' | fzf --no-sort | sed 's/ /_/g')

# quit if nothing was selected
[ -z "$SEL" ] && exit 0

# change cache file accordingly
COUNT=$(grep "^$SEL " "$CACHE" | cut -d' ' -f2)

if [ -z "$COUNT" ]
then
# add entry to cache file
echo "$SEL 1" >> "$CACHE"
else
# substitute count in cache file
sed "s/^$SEL .*$/$SEL $((COUNT+1))/" -i "$CACHE"
fi

# return the selected application
if [ $1 = "fill_in" ]; then
	echo pass $(echo $SEL | sed 's/_/\\ /g') '| { IFS= read -r pass; printf %s "$pass"; } | xdotool type --clearmodifiers --file -'
else
	echo pass -c $(echo $SEL | sed 's/_/\\ /g')
fi
