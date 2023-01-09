#!/bin/bash
FULL_PATH_TO_SCRIPT="$(realpath "$0")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"
# set env to get DOMAIN
if [ ! -f "/root/.env" ]; then
    echo "/root/.env does not exist."
    echo "env_example is template to use"
    exit 2
fi
source /root/.env
if [ -z ${gChat_url+x} ]; then echo "gChat_url must be set"; exit 5; fi
TODAY_DATE=$(date +%s)
mkdir -p "$DIR"
LOG="$DIR/ssl_renewal_report.log"
touch "$LOG"
for line in $(cat /gluster/@/api/lock/renew_certs_hosts.lock)
do
    HOST=$(echo $line | cut -d'-' -f-1)
    LAST_RENEWAL_DATE=$(echo "$line" | rev | cut -d'-' -f 1 | rev)
    TIME_DIFF=$((TODAY_DATE - LAST_RENEWAL_DATE))
    LAST_RAN=$((TIME_DIFF / 3600))
    if [[ $LAST_RAN -le 24 ]]; then
        echo "Warning - $HOST: Certs Renewal process last ran was $LAST_RAN hours ago" >> "$LOG"
    else
        LAST_RAN_IN_HOURS=$((LAST_RAN / 24))
        echo "Warning - $HOST: Certs Renewal process last ran was $LAST_RAN_IN_HOURS days ago" >> "$LOG"
    fi;
done
RESULTS=$(<"$LOG")
curl --location --request POST "${gChat_url}" --header 'Content-Type: application/json' \
 --data-raw "{\"text\": \"SSl Renewal Status : \\n ${RESULTS} \"}"
rm -rf "$LOG"
