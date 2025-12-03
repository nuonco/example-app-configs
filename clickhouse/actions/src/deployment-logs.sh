#!/usr/bin/env sh

set -e
set -o pipefail
set -u

timestamp=`date -Iminutes | sed 's/://g' | sed 's/-//g'`
tmp_location="/tmp/$timestamp.txt"

echo >&2 "showing logs in default namespace..."
kubectl logs --tail=100 -n $DEPLOYMENT_NAMESPACE deployment/$DEPLOYMENT_NAME 2>&1 | tee $tmp_location

exit_code="$?"
logs_txt=`cat $tmp_location`
payload=`jq --null-input --arg exitCode "$exit_code" --arg logs "$logs_txt" '{"exit_code": $exitCode, "logs": $logs}'`
rm $tmp_location
echo $payload | jq -c  >> $NUON_ACTIONS_OUTPUT_FILEPATH
