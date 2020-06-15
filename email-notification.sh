#!/bin/bash

API=${API:-http://validator-api/api/v1}
PREFIX="Loop unprocessed testfiles"

if [[ -n $1 ]]; then
  WSID=$1
  echo "$PREFIX: check whether to send email notification for workspace $WSID"

  # get the workspace info
  HTTP_STATUS=$(curl -s "$API/iati-testworkspaces/$WSID" -o "./tmp_$WSID" -w "%{http_code}")

  if [[ $HTTP_STATUS == 200 ]]; then 
    WS=`cat ./tmp_$WSID`
    RECENT=`date -u --iso-8601=seconds -d "1 hour ago"`

    # if there is an email address 
    # and all datasets have a JSON-updated field
    # and last-email-notification does not exist
    #     or last-email-notification is more than an hour ago
    # then send an email and update the last-email-notification timestamp

    SEND=`echo $WS | jq '[ (has("email") and (.email!=null)), \
      (.datasets | all(has("json-updated"))), \
      ( (has("last-email-notification") | not) \
        or (.["last-email-notification"] < "$RECENT") )] | all'`

    if [[ $SEND == true ]]; then
      # get email, remove leadig and trailing quote
      E1=`echo $WS | jq '.email'`
      E2=${E1#\"}
      EMAIL=${E2%\"}

      cat <<EOF | msmtp $EMAIL
To: $EMAIL
From: no-reply@iatistandard.org
Subject: Your IATI validation results are ready

This is a message from the IATI Validator.

All files uploaded in your workspace have been validated.

Your personal workspace with validation results is here:
https://test-validator.iatistandard.org/validate/$WSID

Your personal workspace (including your email address) will be automatically deleted after 72 hours.

Thank you for your interest in the IATI Standard.
https://www.iatistandard.org

EOF

      if [[ $? == 0 ]]; then
        NOW=`date -u --iso-8601=seconds`
        APIDATA="{\"last-email-notification\": \"$NOW\"}"

        echo "$PREFIX: update last-email-notification for iati-testworkspace '$WSID' ($NOW) to indicate processing"
        curl -sS -X PATCH --header 'Content-Type: application/json' --header 'Accept: application/json' \
        -d "$APIDATA" \
        "$API/iati-testworkspaces/$WSID"
        echo "$PREFIX: email notification sent for workspace $WSID"
      else
        echo "$PREFIX: email notification failed for workspace $WSID"
      fi
    fi
  fi
fi
