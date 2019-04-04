#!/bin/bash

set -u

help() {
  echo ''
  echo "$(basename "$0") a dsh like tool for Heroku"
  echo "$(basename "$0") [-A|-a application1,application2,...|-g groupname|-r] [-d] [-q] [-t] heroku-command"
  echo "$(basename "$0") -h"
  echo "$(basename "$0") -G"
  echo "$(basename "$0") -r"
  echo ''
  echo 'run heroku command on defined applications or applications group'
  echo ''
  echo "  -A"
  echo "    run command against all applications"
  echo "    an aplications is a file listing applications (one per line)"
  echo "    it is searched into ${HOME}/.dheroku/dheroku/applications.list file"
  echo "    if not found it is searched into /etc/dheroku/applications.list file"
  echo ''
  echo "  -a"
  echo "    append application(s)"
  echo "    applications names are splitted by comma"
  echo ''
  echo "  -d"
  echo "    debug mode (being verbose)"
  echo ''
  echo "  -h"
  echo "    show this help"
  echo ''
  echo "  -G"
  echo '    list groups'
  echo ''
  echo "  -g groupname"
  echo "    run command on groupname's applications"
  echo "    a group is a file listing applications (one per line)"
  echo "    it is searched into ${HOME}/.dheroku/dheroku/group/ directory"
  echo "    if not found it is searched into /etc/dheroku/group/ directory"
  echo ''
  echo "  -r"
  echo "    regenarate applications list (grabbing them from existing groups)"
  echo ''
  echo "  -q"
  echo "    hide application name when displaying command results"
  echo ''
  echo "  -t"
  echo "    dry run, will show debug then exit"
  echo ''
  exit "${1:-1}"
}

debug() {
  [ "$DEBUG" = "debug" ] && echo -e "\033[0;33m${1}\033[0m"
}

error() {
  echo ''
  echo -e "\033[0;31m${1}\033[0m"
  help "${2:-1}"
}

USER_DHEROKU="${HOME}/.dheroku/"
SYSTEM_DHEROKU="/etc/dheroku/"


all_applications() {
  local USER_GROUP="${USER_DHEROKU}applications.list"
  local RESULT=""
  if [[ -r "$USER_GROUP" ]]; then
    # debug 'found'
    RESULT=$(<"$USER_GROUP")
  else
    local GLOBAL_GROUP="${SYSTEM_DHEROKU}/applications.list"
    if [[ -r "$GLOBAL_GROUP" ]]; then
      RESULT=$(<"$GLOBAL_GROUP")
    else
      return 1
    fi
  fi
  echo "$RESULT"
}

GROUP_DIR="${USER_DHEROKU}group/"

list_groups() {
  column -t  <(
    for FILE in  ${GROUP_DIR}* ; do
      echo "$(basename ${FILE}) $(wc -l < "${FILE}") applications"
    done
    for FILE in  ${GROUP_DIR}* ; do
      echo "$(basename ${FILE}) $(wc -l < "${FILE}") applications"
    done

  )
  exit 0
}

regenerat_all() {
  cat ${GROUP_DIR}* | sort | uniq | sed '/^\s*$/d' > "${USER_DHEROKU}applications.list"
}

group_applications() {
  local GROUP_NAME="$1"
  local USER_GROUP="${GROUP_DIR}${GROUP_NAME}"
  local RESULT=""
  if [[ -r "$USER_GROUP" ]]; then
    # debug 'found'
    RESULT=$(<"$USER_GROUP")
  else
    local GLOBAL_GROUP="${SYSTEM_DHEROKU}group/${GROUP_NAME}"
    if [[ -r "$GLOBAL_GROUP" ]]; then
      RESULT=$(<"$GLOBAL_GROUP")
    else
      return 1
    fi
  fi
  echo "$RESULT"
}

application_command() {
  local APPLICATION="$1"
  local COMMAND="$2"
  local RESULT
  RESULT=$(heroku "$COMMAND" -a "$APPLICATION" 2>/dev/null)

  if [ $? = 1 ] ; then
    echo -ne "\033[0;31mthe following command failed\033[0m: "
    echo "heroku $COMMAND -a $APPLICATION"
  else
    echo "$RESULT" | while IFS= read -r LINE
    do
      [ -n "$VERBOSE" ] && echo -n "$APPLICATION: "
      echo "$LINE"
    done
  fi
}

(($# == 0)) && help && exit 1
APPLICATIONS=""
ALL_APPLICATIONS=""
COMMAND=""
DEBUG=""
GROUP_NAME=""
VERBOSE="yes"

while getopts ":a:Ac:dGg:hqrt" OPT; do
  case $OPT in
    A)
      ALL_APPLICATIONS="yes"
    ;;
    a)
      APPLICATIONS="$(echo $OPTARG| tr "," "\n")"
    ;;
    c)
      COMMAND=$OPTARG
    ;;
    d)
      DEBUG="debug"
    ;;
    G)
      list_groups
    ;;
    g)
      GROUP_NAME=$OPTARG
    ;;
    h)
      help 0
    ;;
    q)
      VERBOSE=""
    ;;
    r)
      regenerat_all
      exit 0
    ;;
    t)
      DEBUG="dryrun"
    ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
    ;;
    \?)
     help
    ;;
    *)
     help
    ;;
  esac
done
shift $((OPTIND-1))

if [ -n "$ALL_APPLICATIONS" ]; then
  APPLICATIONS="$APPLICATIONS"'\n'"$(all_applications)"
  [ "$?" = "1" ] && error "Couldn't find applications.list file"
fi

if [ -n "$GROUP_NAME" ]; then
  APPLICATIONS="$APPLICATIONS"'\n'"$(group_applications "$GROUP_NAME")"
  [ $? = 1 ] && error "Couldn't find ${GROUP_NAME} group"
fi


[ -z "$COMMAND" ] && COMMAND="$*"
[ -z "$COMMAND" ] && error "You must specify a command to run"
debug "Will run the following command: $COMMAND"

if [ "$DEBUG" = "dryrun" ] ; then
  DEBUG="debug"
  echo ''
  debug "Will run $COMMAND against the following applications:"
  echo -e "$APPLICATIONS"
  echo ''
  exit 0
fi

for APPLICATION in $(echo -e $APPLICATIONS) ; do
  application_command "$APPLICATION" "$COMMAND"
done

