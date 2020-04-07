#!/bin/bash
SECONDS=0

# Args here
  OBJECT="Account"
  FILENAME_PREFIX="acc"
# End args here


set -e
GREEN="\033[32;1m"
WHITE="\033[97;1m"
RED="\033[91;1m"
RESTORE="\033[0m"
FILENAME="${FILENAME_PREFIX}-${OBJECT}.json"

USAGE="$0 [--target <org-alias>] [--flush-data]"
ORG_NAME=""
FLUSH_DATA="false"

while [ $# -gt 0 ] ; do
  case $1 in
    -t | --target) ORG_NAME="$2"
                   shift;;
    --flush-data) FLUSH_DATA="true" ;;
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
    echo 'eg: import --target MyScrOrg1'
    exit 1
fi

cd "$(dirname "$BASH_SOURCE")"
echo -e "${GREEN}*** ${WHITE}Import data script\n${GREEN}* ${WHITE}by vc@vaughancrole.com${RESTORE}\n"

echo -e "Object [${WHITE}${OBJECT}${RESTORE}]\n"

if [[ $FLUSH_DATA == "true" ]]; then
    echo -e "${GREEN}*** ${WHITE}Flushing data...${RESTORE}"

    # Auto gen delete.apex
    if [ ! -f delete.apex ]; then
        echo -e "delete [SELECT Id FROM ${OBJECT}];" > delete.apex
    fi
    sfdx force:apex:execute -f delete.apex -u ${ORG_NAME}
    rm delete.apex
fi

echo -e "${GREEN}*** ${WHITE}Importing data...${RESTORE}"
sfdx force:data:tree:import -f ${FILENAME} -u ${ORG_NAME}

echo -e "Time taken: ${SECONDS} seconds.\n"
exit 0;
