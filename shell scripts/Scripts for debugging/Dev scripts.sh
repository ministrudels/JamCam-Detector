#!/usr/bin/env bash
# Run docker
# --rm              cleanup filesystem
# -it               with interactive mode (waits for input)
# -d                with detached mode
# --name            with name
# --mount source=TfLfeeds,target=/TfLfeeds              with volume mounted
# -v /var/run/docker.sock:/var/run/docker.sock          attach docker socket
# <target image>

printf "\nCleaning all existing containers\n"
docker stop $(docker ps -a -q)
docker update --restart=no $(docker ps -a -q)
docker rm $(docker ps -a -q)


# Run YOLO container with volume CPU
docker run --rm -it -d --name cpu_darknet --mount source=TfLfeeds,target=/TfLfeeds ganhuanmin/cpudarknet

# Run YOLO container with volume GPU
nvidia-docker run --rm -it -d --name gpu_darknet --mount source=TfLfeeds,target=/TfLfeeds ganhuanmin/gpudarknet

# Run input feed container
docker run --rm -it --name test_input --mount source=TfLfeeds,target=/TfLfeeds -v /var/run/docker.sock:/var/run/docker.sock ganhuanmin/inputfeeds
docker run --rm -it --name test_input --mount source=TfLfeeds,target=/TfLfeeds -v /var/run/docker.sock:/var/run/docker.sock inputfeeds

# Run parse dn logs container
docker run --rm -it --name parseLogs -v /var/run/docker.sock:/var/run/docker.sock parse_dn cpu_darknet

# Kill all containers
FOR /f "tokens=*" %i IN ('docker ps -q') DO docker kill %i

# Small image to view the volume
docker run --rm -it --name view --mount source=TfLfeeds,target=/TfLfeeds fedora
docker run --rm -it --name view --mount source=debug_videos,target=/debug_videos fedora

# Run container to create debug version of a video
nvidia-docker run -it --mount source=TfLfeeds,target=/TfLfeeds test_opencv "/TfLfeeds/JamCams_00002.00882/700146bbb399bdee9a47a869e40bc551/700146bbb399bdee9a47a869e40bc551.mp4 -out_filename /TfLfeeds/JamCams_00002.00882/debug.mp4 -dont_show"

# Run download container with binding to host filesystem
docker run --rm --net=host -v ~/TfL_videos:/TfLfeeds store_videos local 751 911

# With a folder called "debug_pictures in the main directory with pictures to generate output on, run the below.
# This creates the detection images in the host debug_pictures directory
docker run --rm -d --name debug -it --mount type=bind,source="$(pwd)"/debug_pictures,target=/debug_pictures --entrypoint "/bin/bash" output_detected_video
docker cp shell\ scripts/Scripts\ for\ debugging/improving_darknet.sh debug:/darknet/
docker attach debug
./improving_darknet.sh