#!/bin/bash
SECONDS=0

set -e
GREEN="\033[32;1m"
WHITE="\033[97;1m"
RED="\033[91;1m"
RESTORE="\033[0m"

# args
  USAGE="$0 [--set <branch name>] [--restore]"
  CI_BRANCH=""
  MODE=""

  while [ $# -gt 0 ] ; do
    case $1 in
      -s | --set) CI_BRANCH="$2"
                  MODE="set"
                  shift;;
      -r | --restore) MODE="restore"
                      CI_BRANCH="default";;
      -h | --help) echo "$USAGE"
                  exit 0;;
      *) echo -e "${RED}*** ERROR: ${RESTORE}Invalid option: ${WHITE}$1${RESTORE}. See usage:"
        echo -e "$USAGE"
        exit 1;;
    esac
    shift
  done

  if [[ $MODE == '' ]]; then
    echo -e "Error: no mode selected."
    exit 1;
  fi
# end args

setProcess()
{
  # get branch name
  CI_BRANCH="$(echo "$1" | cut -d "/" -f1)";
  #echo -e "Branch: $CI_BRANCH";

  # get file name and path
  FILE="${1#$CI_BRANCH/}"
  FILE="$(echo -e "${FILE}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" # trim whitespace
  #echo -e "File: \"$FILE\"";

  cd ..
  # pwd

  # for each file, back up original into default dir
  if [[ ${CI_BRANCH} != "default" ]]; then
    rsync -R "$FILE" "targets/default"
  fi

  # for each file, copy target file into force-app dir
  echo -e "${GREEN}Changing file ${WHITE}${FILE}${GREEN}.${RESTORE}"
  cp "targets/$CI_BRANCH/$FILE" "$FILE"

  if [[ ${CI_BRANCH} == "default" ]]; then
    rm "targets/$CI_BRANCH/$FILE"
  fi
}
export -f setProcess


cd "$(dirname "$BASH_SOURCE")"
echo -e "${GREEN}*** ${WHITE}Dynamic metadata deployment script\n${GREEN}* ${WHITE}by vc@vaughancrole.com${RESTORE}\n"

if [[ $MODE == 'set' ]]; then
  echo -e "${GREEN}* Check for Dynamic metadata deploy changes${RESTORE}"

  # Ensure ${CI_BRANCH} not null
  if [[ ${CI_BRANCH} == "" ]]; then
    echo -e "Error: No branch selected."
    exit 1;
  fi

  if [[ ${CI_BRANCH} == "default" ]]; then
    echo -e "Error: That's not a branch: ${CI_BRANCH}"
    exit 1;
  fi

  # Ensure default is null
  if [[ -d "default" ]]; then
    echo -e "Error: default already exists.\n"
    echo -e "If the deploy script recently errored, then you can try resetting the dynamic metadata and trying again."
    echo -e "run: ${WHITE}targets/dynamic-metadata.sh --restore${RESTORE} to reset.\n"
    exit 1;
  fi

  # Test for branch, if not found, no changes required.
  if [[ -d "${CI_BRANCH}" ]]; then
    echo -e "Dynamic metadata found."
  else
    echo -e "No metadata deploy changes required.\n"
    exit 0;
  fi

  # *
  # * Run Dynamic Swapsie
  # *

  # Find files in target branch, iterate
  echo -e "\n${GREEN}*** Dynamic meta rewrite: Updating files for [${WHITE}${CI_BRANCH}${GREEN}] branch.${RESTORE}"
  find "${CI_BRANCH}" -type f -exec bash -c 'setProcess "$0"' {} \;

  # done.
  echo -e "All done.\n";

elif [[ $MODE == 'restore' ]]; then
  echo -e "${GREEN}* Check for Dynamic metadata deploy changes${RESTORE}"

  # Test for branch, if not found, no changes required.
  if [[ -d "${CI_BRANCH}" ]]; then
    echo -e "Dynamic metadata found."
  else
    echo -e "No metadata deploy changes required.\n"
    exit 0;
  fi

  # *
  # * Run Dynamic Swapsie
  # *

  # Restore files.
  echo -e "\n${GREEN}*** Dynamic meta rewrite: Restoring files.${RESTORE}"
  find "${CI_BRANCH}" -type f -exec bash -c 'setProcess "$0"' {} \;

  # delete default.
  rm -rf default

  # done.
  echo -e "All done.\n";

else
  echo -e "Error: Bad mode: $MODE"
  exit 1;
fi
