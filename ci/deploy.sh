#!/bin/bash
SECONDS=0

# Set up env vars here
  #set -e
  GREEN="\033[32;1m"
  WHITE="\033[97;1m"
  RED="\033[91;1m"
  RESTORE="\033[0m"

  CI_EVENT_TYPE="${TRAVIS_EVENT_TYPE}"
  CI_BRANCH="${TRAVIS_BRANCH}"
  CI_NEW_BRANCH="${CI_BRANCH}"
  CI_CMP_BRANCH="${CI_BRANCH}^"
  CI_PULL_REQUEST="${TRAVIS_PULL_REQUEST}"
  CI_PULL_REQUEST_BRANCH="${TRAVIS_PULL_REQUEST_BRANCH}"
# end set up env vars

usage()
{
    echo -e "${GREEN}*** ${WHITE}Deploy to Salesforce script v${VERSION} by vc@vaughancrole.com${RESTORE}\n"
    echo -e "Usage:"
    echo -e "${WHITE}$0 [--target <branch name>] [--real-deploy] [--skip-code-coverage] [--skip-destruct-check] [--destruct-pre-deploy] [--queue-deploy]${RESTORE}"
}
export -f usage

# args
  VERSION="1.1 b31"
  REAL_DEPLOY="false"
  TEST_CODE="-l RunLocalTests"
  VALI_FLAG="-c"
  DESTRUCT="true"
  PRE_DEST="false"
  DEPLOY_WAIT="33"
  AUTO_CI="false"
  MAIN_BRANCH="false"
  REWRITE="false"

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

  authUrlKey()
  {
    ### Get url key and authenticate
    CI_ORG_FILE="ci/auth-url.txt"
    if [[ $URL_KEY == "" ]]; then
      echo -e "Error: URL Key not set.\n"
      exit 1;
    fi
    echo "${URL_KEY}" > ${CI_ORG_FILE}

    sfdx force:auth:sfdxurl:store -f ${CI_ORG_FILE} -a ciorg
    #sfdx force:org:display -u ciorg
    rm ${CI_ORG_FILE}
  }
  export -f authUrlKey

  checkDestructive()
  {
    # Check for destructive changes
    rm -rf destructive
    echo -e "${GREEN}* Check for destructive changes${RESTORE}\n"
    sfpackage -x $CI_CMP_BRANCH $CI_NEW_BRANCH destructive -p 46

    if [ -f destructive/unpackaged/destructiveChanges.xml ]; then
      echo -e "${GREEN}*** ${RED}Destructive changes found ${GREEN}***"
    else
      echo -e "No destructive changes found.\n"
      rm -rf destructive
    fi
  }
  export -f checkDestructive

  function finish
  {
    EXIT_CODE=$?
    if [[ $REWRITE == "true" ]]; then
      targets/dynamic-metadata.sh --restore
    fi

    if [[ $EXIT_CODE > 0 ]]; then
      echo -e "${RED}*** Error. Stopping script.${RESTORE}"
    fi

    echo -e "${GREEN}* ${WHITE}Deploy Script End."
    echo -e "Time taken: ${SECONDS} seconds.\n"
    exit $EXIT_CODE
  }
  trap finish EXIT
# end functions

echo -e "\n${GREEN}*** ${WHITE}Deploy to Salesforce script v${VERSION}\n${GREEN}* ${WHITE}by vc@vaughancrole.com${RESTORE}\n"

# Display header
if [[ $AUTO_CI != "false" ]]; then
  echo -e "${GREEN}* Running in CI Automatic mode.${RESTORE}\n"
fi
echo "Event: $CI_EVENT_TYPE"
echo "Branch: $CI_BRANCH"
if [[ $CI_NEW_BRANCH != $CI_BRANCH ]]; then
  echo "New Branch: $CI_NEW_BRANCH"
fi
echo "Pull Request: $CI_PULL_REQUEST"
if [[ $CI_PULL_REQUEST != "false" ]]; then
  echo "PR Branch: $CI_PULL_REQUEST_BRANCH"
  CI_CMP_BRANCH="${CI_PULL_REQUEST_BRANCH}"
fi
echo "Compare Branch: $CI_CMP_BRANCH"

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

echo ""

if [[ $AUTO_CI == "false" ]]; then
  exit
fi

if [[ $CI_BRANCH == 'develop' || $CI_BRANCH == 'validation' || $CI_BRANCH == 'release' || $CI_BRANCH == 'master' ]]; then
  MAIN_BRANCH="true"
fi


if [[ $CI_EVENT_TYPE == 'pull_request' ]] && [[ $MAIN_BRANCH == 'true' ]]; then

  echo -e "${GREEN}*** ${WHITE}PR into $CI_BRANCH - running simulation test${RESTORE}\n"

  ### Get url key and authenticate
  authUrlKey

  # Run Dynamic metadata rewrite on deploy
  REWRITE="true"
  targets/dynamic-metadata.sh --set ${CI_BRANCH}

  #####
  # Run simulation deployment
  #####
  sfdx force:source:deploy --checkonly --testlevel=RunLocalTests --sourcepath=force-app/main/default --wait=${DEPLOY_WAIT} -u ciorg

  # Restore dynamic metadata rewrite
  #targets/dynamic-metadata.sh --restore

elif [[ $CI_EVENT_TYPE == 'push' ]] && [[ $MAIN_BRANCH == 'true' ]]; then

  echo -e "${GREEN}*** ${WHITE}Push into $CI_BRANCH - running deploy${RESTORE}\n"

  ### Get url key and authenticate
  authUrlKey

  # Run Dynamic metadata rewrite on deploy
  REWRITE="true"
  targets/dynamic-metadata.sh --set ${CI_BRANCH}


  ### Destructive changes
  if [[ $DESTRUCT == 'true' ]]; then
    checkDestructive

    # Pre-deploy push destructive changes
    if [[ -f destructive/unpackaged/destructiveChanges.xml ]] && [[ $PRE_DEST == 'true' ]]; then
      echo -e "\n${GREEN}* Pre-deploy: Push destructive changes${RESTORE}\n"
      sfdx force:mdapi:deploy --deploydir=destructive/unpackaged --ignoreerrors --ignorewarnings --wait=-1 -u ciorg
    fi
  fi


  #####
  # Run main deployment
  #####
  echo -e "${GREEN}*** ${RED}Real deploy ${GREEN}***${RESTORE}\n"
  sfdx force:source:deploy --testlevel=RunLocalTests --sourcepath=force-app/main/default --wait=${DEPLOY_WAIT} -u ciorg
  #pause


  # Post-deploy push destructive changes
  if [[ -f destructive/unpackaged/destructiveChanges.xml && $PRE_DEST == 'false' ]]; then
    echo -e "\n${GREEN}* Post-deploy: Push destructive changes${RESTORE}\n"
    sfdx force:mdapi:deploy --deploydir=destructive/unpackaged --ignoreerrors --ignorewarnings --wait=-1 -u ciorg
  fi


  # Restore dynamic metadata rewrite
  #targets/dynamic-metadata.sh --restore


else
  echo -e "${GREEN}*** ${WHITE}No action required.\n"

fi
