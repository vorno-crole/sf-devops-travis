#!/bin/bash
SECONDS=0

set -e
GREEN="\033[32;1m"
WHITE="\033[97;1m"
RED="\033[91;1m"
RESTORE="\033[0m"

if [[ $EMAIL_ADDR == '' ]]; then
    EMAIL_ADDR="$(git config --get user.email)"
fi

usage()
{
    echo -e "${GREEN}*** ${WHITE}Set Email script by vc@vaughancrole.com${RESTORE}\n"
    echo -e "Sets your current default org user email. Useful for scratch orgs. Usage:"
    echo -e "${WHITE}$0 (--email <email addr>)${RESTORE}\n"
    echo -e "You can also set the env var ${GREEN}EMAIL_ADDR${RESTORE} to automate this script. try:"
    echo -e "${WHITE}export EMAIL_ADDR=\"vc@vaughancrole.com\"${RESTORE}"
    echo -e "then run this script with no parameters."
}
export -f usage

while [ $# -gt 0 ] ; do
    case $1 in
        -e | --email) EMAIL_ADDR="$2"
                      shift;;
        -h | --help) usage
                     exit 0;;
        *) echo -e "${RED}*** ERROR: ${RESTORE}Invalid option: ${WHITE}$1${RESTORE}. See usage:"
           usage
           exit 1;;
    esac
    shift
done

cd "$(dirname "$BASH_SOURCE")"

# what is your email?
echo -e "Email addr: ${EMAIL_ADDR}"

# get user id
USER_ID="$(sfdx force:apex:execute -f getUserId.apex | egrep USER_DEBUG | cut -d "\"" -f 2)"
echo -e "User Id found: ${USER_ID}"

# set user record
echo -e "Performing update..."
sfdx force:data:record:update -s User -i ${USER_ID} -v "Email=${EMAIL_ADDR}" --json | egrep \"success\"

# read record
sfdx force:data:record:get -s User -i ${USER_ID} --json | egrep \"Email\"

echo -e "\nDon't forget to check your email and click on the link to confirm email change."

echo -e "Time taken: ${SECONDS} seconds.\n"
