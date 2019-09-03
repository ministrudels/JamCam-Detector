#!/usr/bin/env bash

start_time="$(date -u +%s)"
docker volume rm TfL_videos

printf "\nRunning fill video store containers, storing local\n"
docker run --rm -d --net=host -v /TfL_videos:/TfL_videos store_videos local 0 150
docker run --rm -d --net=host -v /TfL_videos:/TfL_videos store_videos local 151 300
docker run --rm -d --net=host -v /TfL_videos:/TfL_videos store_videos local 301 450
docker run --rm -d --net=host -v /TfL_videos:/TfL_videos store_videos local 451 600
docker run --rm -d --net=host -v /TfL_videos:/TfL_videos store_videos local 601 750
docker run --rm --net=host -v /TfL_videos:/TfL_videos store_videos local 751 911

printf "\nWaiting for API to update its response...."
curl http://127.0.0.1:8080/TFLcamera/update_JamCam_res

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

printf "\n\t\tFinished at downloading and detecting freshest feeds as of $start_time"