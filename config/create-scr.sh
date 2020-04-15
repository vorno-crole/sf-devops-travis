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

# Test for dev hub
DEV_HUB_NAME="$(sfdx force:config:get defaultdevhubusername --json | egrep value | cut -d "\"" -f 4)"
if [[ $DEV_HUB_NAME == "" ]]; then

    # No dev hub. Auto create?

    if [[ $DEV_HUB_KEY == "" ]]; then
        # No dev hub url key. Error.
        echo -e "Error: No Dev hub."
        exit 1;
    fi

    DEVHUB_ORG_FILE="devhub-url.txt"
    echo "${DEV_HUB_KEY}" > ${DEVHUB_ORG_FILE}
    sfdx force:auth:sfdxurl:store -f ${DEVHUB_ORG_FILE} -a DevHub --setdefaultdevhubusername
    rm ${DEVHUB_ORG_FILE}
fi


echo -e "${GREEN}* ${RESTORE}Creating scratch org: ${WHITE}$1${RESTORE}."

cd "$(dirname "$BASH_SOURCE")"
sfdx force:org:create -f project-scratch-def.json -d 30 -a $1 -s
#sfdx force:org:display
#sfdx force:mdapi:deploy -d packages -w -1
sfdx force:source:push

# Load data
#../data/myObject/import.sh -t $1

#sfdx force:org:open
echo -e "\nTime taken: ${SECONDS} seconds.\n"
echo ""
