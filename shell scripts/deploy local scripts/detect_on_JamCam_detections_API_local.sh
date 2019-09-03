#!/usr/bin/env bash
TIME_LIMIT=60

while true
do
    start_time="$(date -u +%s)"

    docker system prune -f --volumes

    printf "\nRunning darknet container\n"
#    docker run --gpus all --rm -it -d --name gpu_darknet --mount source=TfLfeeds,target=/TfLfeeds ganhuanmin/gpudarknet:normal -thresh 0.05
    docker run --gpus all --rm -it -d --name gpu_darknet --mount source=TfLfeeds,target=/TfLfeeds ganhuanmin/gpudarknet:tensor_core -thresh 0.05


    printf "\nRunning input containers\n"
    docker run --rm -d --name test_input1 --net=host --mount source=TfLfeeds,target=/TfLfeeds -v /var/run/docker.sock:/var/run/docker.sock inputfeeds_detection local gpu_darknet 0 182
    docker run --rm -d --name test_input2 --net=host --mount source=TfLfeeds,target=/TfLfeeds -v /var/run/docker.sock:/var/run/docker.sock inputfeeds_detection local gpu_darknet 182 364
    docker run --rm -d --name test_input3 --net=host --mount source=TfLfeeds,target=/TfLfeeds -v /var/run/docker.sock:/var/run/docker.sock inputfeeds_detection local gpu_darknet 364 546
    docker run --rm -d --name test_input4 --net=host --mount source=TfLfeeds,target=/TfLfeeds -v /var/run/docker.sock:/var/run/docker.sock inputfeeds_detection local gpu_darknet 546 728
    docker run --rm -d --name test_input5 --net=host --mount source=TfLfeeds,target=/TfLfeeds -v /var/run/docker.sock:/var/run/docker.sock inputfeeds_detection local gpu_darknet 728 911

    printf "\nRunning log parser container\n"
    docker run --rm --name parseLogs --net=host -v /var/run/docker.sock:/var/run/docker.sock parse_dn_checksum local gpu_darknet

    printf "\nKilling gpu_darknet"
    docker kill gpu_darknet


    end_time="$(date -u +%s)"
    elapsed="$(($end_time-$start_time))"
    now=$(date +"%T")

    printf "\n\t\tFinished at $now. To process all feeds took: $elapsed \n"

    # Sleep for 5 minutes - elapsed time, prevents continually running the shell script immediately
    if [[ "$elapsed" -lt "$TIME_LIMIT" ]]
    then
    sleep_duration="$((TIME_LIMIT-$elapsed))"
    printf "\n\t\t Detections on TfL videos at $start_time completed. Retrying in $sleep_duration seconds\n"
    sleep ${sleep_duration}
    fi
done