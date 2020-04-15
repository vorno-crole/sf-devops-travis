# sf-devops-travis
SF Devops with Travis CI


Branch|Build Status
------|------------
master|[![Build Status](https://api.travis-ci.org/vorno-crole/sf-devops-travis.svg?branch=master)](https://travis-ci.com/github/vorno-crole/sf-devops-travis)
release|[![Build Status](https://api.travis-ci.org/vorno-crole/sf-devops-travis.svg?branch=release)](https://travis-ci.com/github/vorno-crole/sf-devops-travis)
validation|[![Build Status](https://api.travis-ci.org/vorno-crole/sf-devops-travis.svg?branch=validation)](https://travis-ci.com/github/vorno-crole/sf-devops-travis)
develop|[![Build Status](https://api.travis-ci.org/vorno-crole/sf-devops-travis.svg?branch=develop)](https://travis-ci.com/github/vorno-crole/sf-devops-travis)


# Things to configure
- travis.yml. Update the branches as required
- Travis Config - use URL_KEY env var for each environments force:// URL
- Travis Config - use DEV_HUB_KEY env var for dev hub force:// URL
- Lock your branches
- deploy.sh - ensure main branches are set (currently master, release, validation, develop.)
