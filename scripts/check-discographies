#!/usr/bin/bash

bold=$(tput bold)
norm=$(tput sgr0)

########## FUNCTIONS ##########

help() {
  echo "usage: $(basename "$0") <locale> <musicdir>"
}

getdirnames() {
  local dirs=($1/*)
  for dir in ${dirs[@]}; do
    if [[ -d $dir ]]; then
      dirnames+=(`basename $dir`)
    fi
  done
  printf "%s\n" "${dirnames[@]}"
}

extractyears() {
  local -n list=$1
  local res=()
  for i in ${!list[@]}; do
    res+=( $(echo ${list[i]} | egrep -o '[0-9]{4}') )
  done
  printf "%s\n" "${res[@]}"
}

removeyears() {
  local -n list=$1
  local res=()
  for i in ${!list[@]}; do
    res+=( $(echo ${list[i]} | sed -e 's/ \?([0-9]\{4\})//g') )
    res[i]=$(echo ${res[i]} | sed -e 's/[0-9]\{4\}: //g') # in case of pattern "1234: Name"
  done
  printf "%s\n" "${res[@]}"
}

sortdiscog() {
  local -n albumarray=$1
  local -n yeararray=$2
  local resarray=()
  for index in ${!yeararray[@]}; do
    resarray+=("${yeararray[index]}|${albumarray[index]}")
  done
  mapfile -t resarray < <(printf '%s\n' "${resarray[@]}" | sort -n)
  for index in ${!resarray[@]}; do
    yeararray[index]=${resarray[index]%\|*}
    albumarray[index]=${resarray[index]#*\|}
  done
}

printdiscog() {
  local band=$1
  local -n albumlist=$2
  local -n yearlist=$3
  printf "${bold}%-${col1width}s %2s %-${col2width}s %s\n${norm}" $band ${#albumlist[@]} "albums" "year"
  for j in ${!albumlist[@]}; do
    printf "%${col1width}s  %-${col2width}s   %s\n" "" ${albumlist[j]} ${yearlist[j]}
  done
}

getwikisections() {
  local band=$1
  local wikibandname=${band// /_}
  local url="https://$locale.wikipedia.org/w/api.php?action=parse&page=$wikibandname&prop=sections&format=json"
  log "url: [$url]"
  local cont=$(curl -sS "$url")
  #local cont=$(cat $musicdir/../wikicont/$wikibandname.txt)
  if [[ "$cont" == *"\"error\":{"* ]]; then
    log "query resulted in error"
  elif [[ "$cont" != *"\"sections\":[{"* ]]; then
    log "received content data do not contain \"sections\" tag"
  else
    cont=${cont#*\"sections\":[\{}
    cont=${cont%\}]*}
    local sections=( ${cont//\},\{/$IFS} )
    #log ${sections[@]}
    printf "%s\n" "${sections[@]}"
  fi
}

getdiscogidx() {
  local -n sectionlist=$1
  local searchterms=("Studio albums" "Discography" "Albums")
  for term in ${searchterms[@]}; do
    log "checking sections for term \"$term\""
    for s in ${sections[@]}; do
      line=$(echo $s | grep "$term")
      if [[ -n $line ]]; then
        local substr=${line#*index\":\"}
        substr=${substr%\",\"fromtitle*}
        echo $substr
      fi
    done
    if [[ -n $substr ]]; then
      log "found section \"$term\""
      break;
    fi
  done
  if [[ -z $substr ]]; then
    log "no matching sections found"
    echo "-1"
  fi
}

getwikicontent() {
  local band=$1
  local index=$2
  local wikibandname=${band// /_}
  local url="https://$locale.wikipedia.org/w/api.php?action=parse&page=$wikibandname&section=$index&prop=text&format=json"
  log "url: [$url]"
  local cont=$(curl -sS "$url")
  #local cont=$(cat $musicdir/../wikicont/$wikibandname-cont.txt)
  substr=${cont#*\"text\":\{\"*\":\"} #strtail json
  substr=${substr%\"\}*} #strhead json
  if [[ "$substr" =~ "<table" ]]; then
    log "found table in source, resolving..."
    substr=$(resolvetable $substr)
  else
    substr=$(echo $substr | sed -e 's/<[^>]*>//g') #strip html-tags
  fi
  cont=( ${substr//\\n/$IFS} )
  log ${cont[@]}
  filtered=( $(printf "%s\n" "${cont[@]}" | egrep "\([[:digit:]]{4}\)") )
  if [[ -z $filtered ]]; then
    log "no match found with pattern \"(1234)\", trying \"1234:\""
    filtered=( $(printf "%s\n" "${cont[@]}" | egrep "[[:digit:]]{4}:") )
  fi
  printf "%s\n" "${filtered[@]}"
}

resolvetable() {
  local contstr=$1
  local tablestr=${contstr#*<table*>} #strtail table
  tablestr=${tablestr%<\/table>*} #strhead table
  tablestr=${tablestr//\\n/\|}
  tablestr=${tablestr//<tr>/}
  local rows=( ${tablestr//<\/tr>/$IFS} )
  # if [[ "${rows[0]}" =~ "<th>" ]]; then
  #   local header=${rows[0]}
  # fi
  rows=( $(printf "%s\n" "${rows[@]}" | egrep "[[:digit:]]{4}") )
  # if [[ -n "$header" ]]; then
  #   header=${header//<th>/}
  #   #header=${header//\|/}
  #   local columns=${header//\|/}
  #   columns=( ${columns//<\/th>/$IFS} )
  #   log "columns: " ${columns[@]}
  #   header=${header//<\/th>/}
  # fi
  # [[ -n $header ]] && log "header: " "$header"
  rows=( $(printf "%s$IFS" ${rows[@]} | sed -e 's/<[^>]*>//g') ) #strip html-tags
  log ${rows[@]}
  for i in ${!rows[@]}; do
    local entries=( ${rows[i]//\|/$IFS} )
    for entry in ${entries[@]}; do
      if [[ -n $entry ]]; then
        if [[ "$entry" =~ [[:digit:]]{4} ]]; then
          tableyears+=( $entry )
          [[ -n ${tablealbums[i]} ]] && break
        else
          tablealbums+=( $entry )
          [[ -n ${tableyears[i]} ]] && break
        fi
      fi
    done
  done
  for i in ${!rows[@]}; do
    output+=( "${tablealbums[i]}(${tableyears[i]})" )
  done
  printf "%s\\n" "${output[@]}"
}

showdiff() {
  diff --color <(((col1width-=2)); printdiscog " " $1 $2) <(((col1width-=2)); printdiscog " " $3 $4)
}

########## MAIN ##########

case $1 in
  -h | --help) help ; exit 1 ;;
  -v | --verbose) verbose=true ; shift ;;
esac

if [ "$verbose" ]; then
  log() { printf "%s\n" "$@" >/dev/tty; }
else
  log() { :; }
fi

if [[ $# -lt 2 ]] ; then
    echo "$(basename "$0"): missing arguments, see -h or --help for usage help"
    exit 1
fi

locale=$1
musicdir=$2

IFS=$'\n' #to avoid many problems with spaces in paths
col1width=30
col2width=40
divwidth=79 #4 - years
divider='.'
echo $totalwidth

echo "checking wiki-discographies for Bands in: ${bold}$musicdir${norm}"
echo ""

bandpaths=($musicdir/*)
bands=( $(getdirnames $musicdir) )

printf "%0.s$divider" {1..79}; echo "" #TODO

for i in ${!bandpaths[@]}; do
  albums=( $(getdirnames ${bandpaths[i]}) )
  years=( $(extractyears albums) )
  albums=( $(removeyears albums) )
  sortdiscog albums years
  printdiscog "[local] ${bands[i]}" albums years
  log "searching $locale.wikipedia.org for artist info"
  sections=( $(getwikisections ${bands[i]}) )
  if [[ ${#sections[@]} = 0 ]]; then
    echo "no data found"
  else
    idx=$(getdiscogidx sections)
    if [[ $idx != -1 ]]; then
      log "wiki-section index: $idx"
      log "getting content of section $idx"
      discogdata=( $(getwikicontent ${bands[i]} $idx) )
      wikiyears=( $(extractyears discogdata) )
      wikialbums=( $(removeyears discogdata) )
      sortdiscog wikialbums wikiyears #pretty much always already sorted, but makes the diff more equal if several albums in 1 year
      printdiscog "[wiki] ${bands[i]}" wikialbums wikiyears
      showdiff albums years wikialbums wikiyears
    else
      echo "index could not be determined"
    fi
  fi
  printf "%0.s$divider" {1..79}; echo ""  #TODO
done

echo ""
echo "[  DONE  ]"
