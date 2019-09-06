#!/usr/bin/env bash

res=$(curl https://api.tfl.gov.uk/Place/Type/JamCam | jq -r .)

for i in {0..911..5}
do

    # Needed for cleanup
    docker system prune -f --volumes
    docker volume rm TfLfeeds
    beginning_time=$(date +"%Y-%m-%d: %T")
    printf "\n Beginning at: ${beginning_time}\n"

    docker run \
    --gpus all \
    --rm -it -d \
    --name gpu_darknet \
    --mount source=TfLfeeds,target=/TfLfeeds \
    ganhuanmin/gpudarknet:tensor_core -thresh 0.05

    printf "\nRunning input containers\n"

    for(( j=0; j < ($n_input); j++ )); do
        element=$(( $i + $j ))
        id=$(echo ${res} | jq -r .[${element}].id)
        echo ${id}
        docker run \
        --rm -d\
        --mount source=TfLfeeds,target=/TfLfeeds \
        -v /var/run/docker.sock:/var/run/docker.sock \
        inputfeeds_db gpu_darknet ${id}
    done


    printf "\nRunning Parsing container\n"
    docker run \
    --rm \
    --name parseLogs \
    -v /var/run/docker.sock:/var/run/docker.sock \
    parse_dn_to_db gpu_darknet

    printf "\nKilling gpu_darknet "
    docker kill gpu_darknet

    end_time=$(date +"%Y-%m-%d: %T")
    printf "\nFinished processing all video feeds from ${id} at ${end_time} beginning at ${beginning_time}. \n"
done
