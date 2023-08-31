#!/bin/bash

# Get code directory and .ENV file that contains environent variables
# for example the URL of the GChat webhook to send alerts to
FULL_PATH_TO_SCRIPT="$(realpath "$0")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"

if [ ! -f "$SCRIPT_DIRECTORY/.ENV" ]; then
    echo "$SCRIPT_DIRECTORY/.ENV does not exist."
    echo "ENV.example is template to use"
    exit 1
fi
# Get those ENV Vars
source "$SCRIPT_DIRECTORY"/.ENV

while true
do
./rootcheck.expect
if (( $? != 0 ))
    then
    echo "Broke it"
     curl --location --request POST "${URL}" --header 'Content-Type: application/json' --data-raw "{\"text\": \" Root Server Issue root.atsign.org:64 did not respond from $LOCATION\"}"
fi
sleep 3
done