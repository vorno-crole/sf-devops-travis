#!/bin/bash
SECONDS=0

# Args here
  OBJECT="Account"
  FILENAME_PREFIX="acc"
  QUERY="SELECT Id, Name, AccountNumber, Industry, Ownership, Rating, Type FROM ${OBJECT} ORDER BY Name"
# End args here


set -e
GREEN="\033[32;1m"
WHITE="\033[97;1m"
RED="\033[91;1m"
RESTORE="\033[0m"

USAGE="$0 --target <org-alias>"
ORG_NAME=""

while [ $# -gt 0 ] ; do
  case $1 in
    -t | --target) ORG_NAME="$2"
                   shift;;
    -h | --help) echo "$USAGE"
                 exit 0;;
    *) echo -e "${RED}*** ERROR: ${RESTORE}Invalid option: ${WHITE}$1${RESTORE}. See usage:"
       echo -e "$USAGE"
       exit 1;;
  esac
  shift
done

if [[ $ORG_NAME == "" ]] ; then
    echo 'Error: Specify your org alias'
    echo 'eg: export --target MyScrOrg1'
    exit 1
fi

cd "$(dirname "$BASH_SOURCE")"
sfdx force:data:tree:export -q "${QUERY}" -x ${FILENAME_PREFIX} -u ${ORG_NAME}

echo -e "Time taken: ${SECONDS} seconds.\n"
exit 0;
