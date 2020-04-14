#!/bin/bash
SECONDS=0

set -e
GREEN="\033[32;1m"
WHITE="\033[97;1m"
BLUE="\033[94;1m"
RED="\033[91;1m"
RESTORE="\033[0m"
USAGE="$0 -u <org name or alias> [-f <output url file name>]"
ORG_NAME=""
FILE_NAME=""

#cd "$(dirname "$BASH_SOURCE")"
echo -e "${GREEN}*** ${WHITE}Generate SFDX Auth URL File script.\nBy ${GREEN}vc@vaughancrole.com${RESTORE}.\n"

while [ $# -gt 0 ] ; do
  case $1 in
    -u ) ORG_NAME="$2"
                   shift;;
    -f | --filename) FILE_NAME="$2"
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
    echo -e "${RED}*** Error: ${RESTORE}Specify your org name or alias. See usage:"
    echo -e "${WHITE}$USAGE${RESTORE}"
    exit 1
fi

if [[ $FILE_NAME == "" ]] ; then
    FILE_NAME="${ORG_NAME}-url.txt"
fi


# TODO: Error Check: file already exists


# run command
echo -e "Org name: ${WHITE}${ORG_NAME}${RESTORE}"
sfdx force:org:display -u ${ORG_NAME} --json --verbose | egrep sfdxAuthUrl | cut -d "\"" -f 4 > ${FILE_NAME}

echo -e "Url file ${WHITE}${FILE_NAME}${RESTORE} created.\n"

echo -e "Time taken: ${SECONDS} seconds."
exit 0;
