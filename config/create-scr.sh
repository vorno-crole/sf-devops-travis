#!/bin/bash
SECONDS=0

set -e
GREEN="\033[32;1m"
WHITE="\033[97;1m"
RED="\033[91;1m"
RESTORE="\033[0m"

if [[ $# -eq 0 ]] ; then
    echo 'Error: Specify your scratch org alias'
    echo 'eg: create-scr MyScrOrg1'
    exit 1
fi

echo -e "${GREEN}* ${RESTORE}Creating scratch org: ${WHITE}$1${RESTORE}."

cd "$(dirname "$BASH_SOURCE")"
sfdx force:org:create -f project-scratch-def.json -d 30 -a $1 -s
sfdx force:org:display
#sfdx force:mdapi:deploy -d packages -w -1
sfdx force:source:push

# Load data
#../data/myObject/import.sh -t $1

#sfdx force:org:open
echo -e "\nTime taken: ${SECONDS} seconds.\n"
echo ""
