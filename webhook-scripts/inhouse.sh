#!/bin/bash
# Process a single file from Google Storage
# Parameters:
# $1 - basename of the file (typically the md5sum of the file)

cd /home 

API=http://validator-api/api
VERSION=`grep 'variable name="schemaVersion"' data-quality/rules/iati.xslt | cut -f 2 -d \> | cut -f 1 -d \<`
basename=$1

# Try to get the file via our API

mkdir -p /workspace/input

HTTP_STATUS=$(curl -s "$API/iati-files/dataworkbench-iati/download/$basename.xml" -o "/workspace/input/$basename.xml" -w "%{http_code}")
echo "Inhouse: retrieved $basename.xml with status $HTTP_STATUS"

# If available:
if [[ $HTTP_STATUS == 200 ]]; then 
  # Make sure we process the file again by removing the target for ant
  rm -f /workspace/dest/$basename.feedback.xml
  # Run the XML check and the rules
  ant -f build-engine.xml -Dfilemask=$basename feedback
  
  # Store the result
  
  echo "Inhouse: store feedback for $basename"
  curl -sS -F "file=@/workspace/dest/$basename.feedback.xml;type=application/xml" "$API/iati-files/dataworkbench-iatifeedback/upload"
  
  FILEDATE=$(date -Iseconds -r /workspace/dest/$basename.feedback.xml)
  
  APIDATA="{\"md5\": \"$basename\", \"feedback-updated\": \"$FILEDATE\", \"feedback-version\": \"$VERSION\"}"
  
  echo "Inhouse: update iati-datasets for feedback on $basename"
  curl -sS -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' \
  -d "$APIDATA" \
  "$API/iati-datasets/update?where=%7B%22md5%22%3A%22$basename%22%7D"
  
  # Run the JSON conversion
  rm -f /workspace/json/$basename.json
  ant -f build-engine.xml -Dfilemask=$basename json
  
  # Store the result
  echo "Inhouse: store json for $basename"
  curl -sS -F "file=@/workspace/json/$basename.json;type=application/json" "$API/iati-files/dataworkbench-json/upload"
  
  FILEDATE=$(date -Iseconds -r /workspace/json/$basename.json)
  
  APIDATA="{\"md5\": \"$basename\", \"json-updated\": \"$FILEDATE\", \"json-version\": \"$VERSION\"}"
  
  echo "Inhouse: update iati-datasets for json on $basename"
  curl -sS -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' \
  -d "$APIDATA" \
  "$API/iati-datasets/update?where=%7B%22md5%22%3A%22$basename%22%7D"
  
  # Run the SVRL conversion
  rm -f /workspace/svrl/$basename.svrl
  ant -f build-engine.xml -Dfilemask=$basename svrl
  
  # Store the result
  
  if xmllint --noout /workspace/svrl/$basename.svrl 2> "/dev/null"; then
    echo "Inhouse: store svrl for $basename"
    curl -sS -F "file=@/workspace/svrl/$basename.svrl;type=application/xml" "$API/iati-files/dataworkbench-svrl/upload"
  
    FILEDATE=$(date -Iseconds -r /workspace/svrl/$basename.svrl)
  
    APIDATA="{\"md5\": \"$basename\", \"svrl-updated\": \"$FILEDATE\", \"svrl-version\": \"$VERSION\"}"
  
    echo "Inhouse: update iati-datasets for svrl on $basename"
    curl -sS -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' \
    -d "$APIDATA" \
    "$API/iati-datasets/update?where=%7B%22md5%22%3A%22$basename%22%7D"
  else
    echo "Inhouse: svrl for $basename is not valid XML"
  fi

fi

# Remove the files from the local node
find /workspace -name "${basename}*" -delete
