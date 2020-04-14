# Targets

This folder contains the deployment files specific to branches/environments.

The `dynamic-metadata.sh` script will copy any relevant SF metadata from the specific target folder into the main force-app folder during a deployment.

And then restores these files at the conclusion of the deployment.

