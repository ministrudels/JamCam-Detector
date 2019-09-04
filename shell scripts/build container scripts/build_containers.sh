#!/usr/bin/env bash

#printf "\nBuilding download_video_to_volume container\n"
#docker build --tag download_video_to_volume "docker_containers/download_video_to_volume/."
#
#printf "\nBuilding output detected video container\n"
#docker build --tag output_detected_video "docker_containers/output_detected_video/."
#
#printf "\nBuilding upload_video container\n"
#docker build --tag upload_video "docker_containers/upload_video/."


printf "\nBuilding download videos container\n"
docker build --tag store_videos "docker_containers/store_videos/."

printf "\nBuilding inputfeeds_detection container\n"
docker build --tag inputfeeds_detection "docker_containers/input_from_API/."

printf "\nBuilding log parser container\n"
docker build --tag parse_dn_checksum "docker_containers/parse_dn_logs/."