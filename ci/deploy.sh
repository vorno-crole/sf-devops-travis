#!/bin/bash
SECONDS=0

# Set up env vars here
  set -e
  GREEN="\033[32;1m"
  WHITE="\033[97;1m"
  RED="\033[91;1m"
  RESTORE="\033[0m"

  CI_EVENT_TYPE="$TRAVIS_EVENT_TYPE"
  CI_BRANCH="${TRAVIS_BRANCH}"
  CI_NEW_BRANCH="${CI_BRANCH}"
  CI_CMP_BRANCH="${CI_BRANCH}^"
  CI_PULL_REQUEST="${TRAVIS_PULL_REQUEST}"
  CI_PULL_REQUEST_BRANCH="${TRAVIS_PULL_REQUEST_BRANCH}"

  CI_URL_PATH="../keys" # TODO fix
# end set up env vars

usage()
{
    echo -e "${GREEN}*** ${WHITE}Deploy to Salesforce script v${VERSION} by vc@vaughancrole.com${RESTORE}\n"
    echo -e "Usage:"
    echo -e "${WHITE}$0 [--target <branch name>] [--real-deploy] [--skip-code-coverage] [--skip-destruct-check] [--destruct-pre-deploy] [--queue-deploy]${RESTORE}"
}
export -f usage

# args
  VERSION="1.0 b30"
  REAL_DEPLOY="false"
  TEST_CODE="-l RunLocalTests"
  VALI_FLAG="-c"
  DESTRUCT="true"
  PRE_DEST="false"
  DEPLOY_WAIT="33"
  AUTO_CI="false"

  while [ $# -gt 0 ] ; do
    case $1 in
      -t | --target) CI_CMP_BRANCH="$2"
                     CI_BRANCH="$2" 
                     shift;;
      -d | --real-deploy) REAL_DEPLOY="true" ;;
      --skip-destruct-check) DESTRUCT="false" ;;
      --destruct-pre-deploy) PRE_DEST="true" ;;
      -s | --skip-code-coverage) TEST_CODE="" ;;
      -q | --queue-deploy) DEPLOY_WAIT="0" ;;
      --automatic) AUTO_CI="true" ;;
      -h | --help) usage
                   exit 0;;
      *) echo -e "${RED}*** ERROR: ${RESTORE}Invalid option: ${WHITE}$1${RESTORE}. See usage:"
         usage
         exit 1;;
    esac
    shift
  done
# end args


# functions
  pause()
  {
    read -p "Press Enter to continue."
  }
  export -f pause
# end functions

echo -e "\n${GREEN}*** ${WHITE}Deploy to Salesforce script v${VERSION}\n${GREEN}* ${WHITE}by vc@vaughancrole.com${RESTORE}\n"

if [[ $AUTO_CI != "false" ]]; then
  echo -e "${GREEN}* Running in CI Automatic mode.${RESTORE}\n"
fi
echo "Event: $CI_EVENT_TYPE"
echo "Branch: $CI_BRANCH"
if [[ $CI_NEW_BRANCH != $CI_BRANCH ]]; then
  echo "New Branch: $CI_NEW_BRANCH"
fi
echo "Compare Branch: $CI_CMP_BRANCH"
echo "Pull Request: $CI_PULL_REQUEST"
if [[ $CI_PULL_REQUEST != "false" ]]; then
  echo "PR Branch: $CI_PULL_REQUEST_BRANCH"
fi

if [[ $TEST_CODE == "" ]]; then
  echo "Skip Test Coverage"
fi

if [[ $DESTRUCT == "true" ]]; then
  echo "Destructive changes check enabled."

  if [[ $PRE_DEST == "true" ]]; then
    echo -e "Any destructive changes will run ${GREEN}PRE${WHITE} deployment."
  else
    echo -e "Any destructive changes will run ${GREEN}POST${WHITE} deployment."
  fi
else
  echo "Destructive changes check disabled."
fi

if [[ $REAL_DEPLOY == 'true' ]]; then
  echo -e "${GREEN}*** ${RED}Deploying for real ${GREEN}***"
  VALI_FLAG=""
else
  echo "Simulation deployment."
fi

echo ""


if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi


if [[ $CI_EVENT_TYPE == 'push' ]] && [[ $CI_BRANCH == 'develop' || $CI_BRANCH == 'validation' || $CI_BRANCH == 'release' || $CI_BRANCH == 'master' ]]; then

  echo -e "${GREEN}*** ${WHITE}Push into $CI_BRANCH - running deploy\n"
  echo -e "\n${GREEN}* ${WHITE}Authenticate org\n"

  echo -e "* ${WHITE}Looking for deploy $CI_BRANCH url"

  if [ -f $CI_URL_PATH/deploy-$CI_BRANCH-url.txt ]; then
    echo -e "File $CI_URL_PATH/deploy-$CI_BRANCH-url.txt found.\n"
  else
    echo -e "\n${GREEN}*** ${WHITE}Error: File not found.\n"
    exit 1;
  fi

  sfdx force:auth:sfdxurl:store -f $CI_URL_PATH/deploy-$CI_BRANCH-url.txt -a ciorg
  #sfdx force:org:display -u ciorg

  echo -e "${RESTORE}"


  # Run Dynamic metadata rewrite on deploy
  #targets/dynamic-metadata.sh --set ${CI_BRANCH} # TODO fix


  # (pre-deploy) destructive changes
  rm -rf destructive
  if [[ $DESTRUCT == 'true' ]]; then
    echo -e "${GREEN}* Check for destructive changes${RESTORE}\n"
    sfpackage -x $CI_CMP_BRANCH $CI_NEW_BRANCH destructive -p 46

    if [ -f destructive/unpackaged/destructiveChanges.xml ]; then
      echo -e "${GREEN}*** ${RED}Destructive changes found ${GREEN}***"

      if [[ $PRE_DEST == 'true' ]]; then
        echo -e "\n${GREEN}* Pre-deploy: Push destructive changes${RESTORE}\n"
        sfdx force:mdapi:deploy ${VALI_FLAG} --deploydir=destructive/unpackaged --ignoreerrors --ignorewarnings --wait=-1 -u ciorg
      fi
    else
      echo -e "No destructive changes found.\n"
      rm -rf destructive
    fi
  fi


  #####
  # Run main deployment
  #####
  if [[ $REAL_DEPLOY == 'true' ]]; then
    echo -e "${GREEN}*** ${RED}Real deploy ${GREEN}***${RESTORE}\n"
  else
    echo -e "\n${GREEN}* Simulation deploy${RESTORE}\n"
  fi
  sfdx force:source:deploy ${VALI_FLAG} ${TEST_CODE} -p force-app/main/default --wait=${DEPLOY_WAIT} -u ciorg
  #pause


  # (post-deploy) destructive changes
  if [[ -f destructive/unpackaged/destructiveChanges.xml && $PRE_DEST == 'false' ]]; then
    echo -e "\n${GREEN}* Post-deploy: Push destructive changes${RESTORE}\n"
    sfdx force:mdapi:deploy ${VALI_FLAG} --deploydir=destructive/unpackaged --ignoreerrors --ignorewarnings --wait=-1 -u ciorg
  fi


  # Restore dynamic metadata rewrite
  #targets/dynamic-metadata.sh --restore # TODO fix


else
  echo -e "${GREEN}*** ${WHITE}No action required.\n"

fi

echo -e "${GREEN}* ${WHITE}Deploy Script End."
echo -e "Time taken: ${SECONDS} seconds.\n"
exit 0;
