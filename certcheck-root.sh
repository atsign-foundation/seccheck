#!/bin/bash
#
DNSERROR="DNS Error "
FULL_PATH_TO_SCRIPT="$(realpath "$0")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"

if [ ! -f "$SCRIPT_DIRECTORY/.ENV" ]; then
    echo "$SCRIPT_DIRECTORY/.ENV does not exist."
    echo "ENV.example is template to use"
    exit 1
fi
source "$SCRIPT_DIRECTORY"/.ENV

PID=$$
mkdir -p "$DIR"
LISTSEC="$DIR/seclistroot.${PID}.log"
DATESEC="$DIR/secdatesroot.${PID}.log"
ISSUESEC="$DIR/secissuesroot.${PID}.log"
CERTISSUESEC="$DIR/certissuesroot.${PID}.log"
#
# Convert Days into seconds
EXPIREDAYS=$(($EXPIREDAYS * 86400))
#
# Get the services
# add root/other servers here
echo "root.atsign.org:64" > $LISTSEC
echo "expired.badssl.com:443" >> $LISTSEC

# Check Expiry Date within X days
echo -n > $DATESEC
for secondary in `cat $LISTSEC`
do
        echo -n "$secondary " > $DATESEC
                 echo | openssl s_client -showcerts -connect $secondary 2>/dev/null | openssl x509 -noout  -checkend $EXPIREDAYS >> $DATESEC
done

# Check results
touch $ISSUESEC
grep -v "Certificate will not expire" $DATESEC > $CERTISSUESEC
TOTALPROBLEMS=$(cat $CERTISSUESEC | wc -l)
CERTPROBLEMSCOUNT=$((TOTALPROBLEMS))



 while IFS= read -r line
 do
 CERTISSUES="${CERTISSUES}"$'\n'"${line}"
 done < $CERTISSUESEC

 EXPIREDAYS=$(($EXPIREDAYS / 86400))

if [[ $TOTALPROBLEMS -gt 0 ]]
then
curl --location --request POST "${URL}" --header 'Content-Type: application/json' --data-raw "{\"text\": \"${CERTPROBLEMSCOUNT} Root Certificates that expire in less than
 $EXPIREDAYS days\n root servers with certificate issues ${CERTISSUES} \n\nFirst up to ${MAX} \"}"
fi
