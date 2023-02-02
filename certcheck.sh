#!/bin/bash
DNSERROR="DNS Error "
FULL_PATH_TO_SCRIPT="$(realpath "$0")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"
# set env to get DOMAIN, DO_KEY and gChat_url
if [ ! -f "/root/.env" ]; then
    echo "/root/.env does not exist."
    echo "env_example is template to use"
    exit 2
fi
source /root/.env
if [ -z ${DOMAIN+x} ]; then echo "DOMAIN must be set"; exit 3; fi
if [ -z ${DO_KEY+x} ]; then echo "DO_KEY must be set"; exit 4; fi
if [ -z ${gChat_url+x} ]; then echo "gChat_url must be set"; exit 5; fi
PID=$$
mkdir -p "$DIR"
LISTSEC="$DIR/seclist.${PID}.log"
DATESEC="$DIR/secdates.${PID}.log"
ISSUESEC="$DIR/secissues.${PID}.log"
DNSISSUESEC="$DIR/dnsissues.${PID}.log"
CERTISSUESEC="$DIR/certissues.${PID}.log"
#
# Convert Days into seconds
EXPIREDAYS=$(($EXPIREDAYS * 86400)) 
#
# Get the services
docker service ls |grep 1/1 |grep -e secondary:"$VERSION" -e registry | awk '{ print $2 $6}' | sed 's/_secondary\*/'.${DOMAIN}'/g' | sed 's/_registry\*/'.${DOMAIN}'/g' | sed 's/->.*$//g' > $LISTSEC
# Cylce through the services
# Check DNS entry
# Check Expiry Date within X days
echo -n > $DATESEC
for secondary in `cat $LISTSEC`
do
        echo -n  ${secondary}: >> $DATESEC
        nslookup  ${secondary//:*/} &>/dev/null
        if [[ $? -eq 0 ]]
         then
            if [[ $secondary != *"reg."* ]]; 
            then
                LBTEST=$(nslookup ${secondary//:*/} | grep $LB | wc -l)
                if [[ $LBTEST -eq 1 ]]
                then
                    echo | openssl s_client -showcerts -connect $secondary 2>/dev/null | openssl x509 -noout  -checkend $EXPIREDAYS >> $DATESEC
                else
                    echo "$DNSERROR: record not pointing to Load Balancer $LB" >> $DATESEC
                fi 
            else
                echo | openssl s_client -showcerts -connect $secondary 2>/dev/null | openssl x509 -noout  -checkend $EXPIREDAYS >> $DATESEC
            fi
        else
            echo "$DNSERROR: record not found" >> $DATESEC
        fi
 done

# Check results
grep -v "Certificate will not expire" $DATESEC > $ISSUESEC
TOTALPROBLEMS=$(cat $ISSUESEC | wc -l)
DNSPROBLEMSCOUNT="$(grep "$DNSERROR" $ISSUESEC| wc -l)"
CERTPROBLEMSCOUNT=$((TOTALPROBLEMS - DNSPROBLEMSCOUNT))

grep "$DNSERROR"  $ISSUESEC| tail -$MAX  > $DNSISSUESEC
grep -v "$DNSERROR"  $ISSUESEC| tail -$MAX > $CERTISSUESEC


 while IFS= read -r line
 do
 CERTISSUES="${CERTISSUES}"$'\n'"${line}"
 done < $CERTISSUESEC

 while IFS= read -r line
 do
 DNSISSUES="${DNSISSUES}"$'\n'"${line}"
 done < $DNSISSUESEC
# move seconds back to days for readout
 EXPIREDAYS=$(($EXPIREDAYS / 86400))
if [[ $TOTALPROBLEMS -gt 0 ]]
then
curl --location --request POST "${gChat_url}" --header 'Content-Type: application/json' --data-raw "{\"text\": \"Total number of secondaries with certificate or DNS problems ${TOTALPROBLEMS}\n\n${CERTPROBLEMSCOUNT} Secondary Certificates that expire in less than $EXPIREDAYS days\n${DNSPROBLEMSCOUNT} Problematic Secondary DNS entries\n\nFirst up to ${MAX} secondaries with issues with certificates ${CERTISSUES} \n\nFirst up to ${MAX} secondaries with DNS issues ${DNSISSUES}\"}"
fi
