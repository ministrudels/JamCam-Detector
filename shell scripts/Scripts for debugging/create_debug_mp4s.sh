#!/usr/bin/env bash
CAMERAS=(JamCams_00001.02151 JamCams_00001.03507 JamCams_00001.07450 JamCams_00001.06592 JamCams_00001.06590 JamCams_00001.06501)
VOLUME_NAME="debug_videos"
OUTPUT_FOLDER="${VOLUME_NAME}/out"
BASE_URL="https://jamcam-detections-api.appspot.com/TFLcamera/videos/"
CHECKSUMS_ARG=''
CHECKSUMS_ARR=()

# Install jq package from official repository
if command -v jq >/dev/null 2>&1 ; then
    printf "jq already installed\n"
else
    apt-get -y install jq
fi

## Uncomment while loop to continually get the latest detected video .avi file
#while true
#do
    start_time="$(date -u +%s)"
    docker volume rm ${VOLUME_NAME}

    # Create checksum array and args
    for camera in "${CAMERAS[@]}"
    do
       request_url="${BASE_URL}${camera}"
       checksum=$(curl ${request_url} | jq -r '.[0].checksum')
       CHECKSUMS_ARG+=${checksum}
       CHECKSUMS_ARG+=' '
       CHECKSUMS_ARR+=(${checksum})
    done

    printf "\nRunning 'download videos to volume' container\n"
    docker run --rm --name download_video --mount source=${VOLUME_NAME},target=/${VOLUME_NAME} download_video_to_volume ${VOLUME_NAME} ${CHECKSUMS_ARG}

    printf "\nRunning 'output detected video' container\n"
    for CHECKSUM in "${CHECKSUMS_ARR[@]}"
    do
        INPUT_VIDEO=/${VOLUME_NAME}/${CHECKSUM}.mp4
        OUTPUT_VIDEO=/${OUTPUT_FOLDER}/${CHECKSUM}.avi
        docker run --gpus all --rm -it --name gpu_darknet_out --mount source=${VOLUME_NAME},target=/${VOLUME_NAME} output_detected_video ${INPUT_VIDEO} -out_filename ${OUTPUT_VIDEO} -dont_show
    done

    printf "\nRunning 'upload videos from volume to GCP' container\n"
    docker run --rm --name upload_video --mount source=${VOLUME_NAME},target=/${VOLUME_NAME} upload_video /${OUTPUT_FOLDER}

    printf "\n Finished getting debug version of videos"

#done

