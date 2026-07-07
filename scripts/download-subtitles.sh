#!/bin/bash

bold=$(tput bold)
norm=$(tput sgr0)

help() {
  echo "usage: $(basename "$0") <lang> <imdb-id> <extension> <file(s)>"
}

ssplit() {
  local string="$1" array=${2:-ssplited_array} delim="${3:- }" pos=0
  while [ "$string" != "${string#*$delim}" ];do
    printf -v $array[pos++] "%s" "${string%%$delim*}"
    string="${string#*$delim}"
  done
  printf -v $array[pos] "%s" "$string"
}

subidprompt() {
  ssplit "$1" lines '#'
  ids=()
  for l in "${lines[@]}"; do
    [[ ! -z "${l// }" ]] && echo -en "#$l" | sed -r 's/.\[.* *" */ - /g' && ids+=("${l:0:10}")
  done
  echo
  idx=0 && length=${#ids[@]}
  echo -en "id: #${ids[$idx]}"
  if [[ $length -gt 1 ]]; then 
    while true; do
      read -r -sn1 t
      case $t in
        A) [[ ! $idx-1 -lt 0 ]]         && echo -en "\rid: #${ids[$idx-1]}" && ((idx-=1)) ;;
        B) [[ ! $idx+1 -gt $length-1 ]] && echo -en "\rid: #${ids[$idx+1]}" && ((idx+=1)) ;;
        C) echo; break ;;
        D) ;;
      esac
    done
  else echo " - only 1 variant, auto-download"
  fi
  subid="${ids[$idx]}"
}

case $1 in
  -h | --help) help ; exit 1 ;;
esac

# exit if not enough arguments
if [[ $# -lt 4 ]] ; then
    echo "$(basename "$0"): missing arguments, see -h or --help for usage help"
    exit 1
fi

lang=$1
id=$2
ext=$3

#echo ":: downloading subtitles in language '$lang' with imdb-id '$id' for extension '$ext'"

for i in "${@:4}"; do 
  if [[ $i == *.$ext ]]; then
    echo "${bold}$i${norm}"
    name=`basename "$i" .$ext`
    read -p "title: " -i "$name" -e filter
    res=$(subdl --lang=$lang --force-imdb --imdb-id=$id -n "$i" | grep -i "$filter")
    echo -------------------------
    subidprompt "$res"
    echo -------------------------
    echo -e "downloading subtile with id=$subid"
    subdl --lang=$lang --force-imdb --imdb-id=$id --download=$subid --existing=overwrite "$i" > /dev/null
    echo
  fi
done

echo "[  DONE  ]"
