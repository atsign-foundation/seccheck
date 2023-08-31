#!/bin/bash

# Get code directory and .ENV file that contains environent variables
# for example the URL of the GChat webhook to send alerts to
FULL_PATH_TO_SCRIPT="$(realpath "$0")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"
ALERTS="0"
MAXCOUNT="3"

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
    echo "Root Server not reponding correctly"
     curl --location --request POST "${URL}" --header 'Content-Type: application/json' --data-raw "{\"text\": \" Root Server Issue root.atsign.org:64 did not respond correctly from $LOCATION\"}"
     ALERTS=$(( $ALERTS + 1 ))

            if (( $ALERTS >= $MAXCOUNT ))
            then
            curl --location --request POST "${URL}" --header 'Content-Type: application/json' --data-raw "{\"text\": \" Root Server Issue repeated consecutively $MAXCOUNT times from $LOCATION sleeping 10 minutes\"}"
            # Sleep 10 minutes to save the noise
            sleep 600
            ALERTS="0"
            # Notify of resumption of service
            curl --location --request POST "${URL}" --header 'Content-Type: application/json' --data-raw "{\"text\": \" Root Server checker from $LOCATION is resuming\"}"
            fi
    else

ALERTS="0"
fi
# sleep as not to hammer root too much
sleep 3
done