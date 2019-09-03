#!/usr/bin/env bash
TIME_LIMIT=180

while true
do
    start_time="$(date -u +%s)"

    curl http://127.0.0.1:8080/TFLcamera/update_JamCam_res
    end_time="$(date -u +%s)"
    elapsed="$(($end_time-$start_time))"

    if [[ "$elapsed" -lt "$TIME_LIMIT" ]]
    then
    sleep_duration="$((TIME_LIMIT-$elapsed))"
    printf "\n\t\t Updated response object Retrying in $sleep_duration seconds\n"
    sleep ${sleep_duration}
    fi
done