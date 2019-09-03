#!/usr/bin/env bash

#printf "\nBuilding download video to volume container\n"
#docker build --tag download_video_to_volume "docker containers/download video to volume/."
#
#printf "\nBuilding output detected video container\n"
#docker build --tag output_detected_video "docker containers/output_detected_video/."
#
#printf "\nBuilding upload video container\n"
#docker build --tag upload_video "docker containers/upload video/."


printf "\nBuilding download videos container\n"
docker build --tag store_videos "docker containers/store videos/."

printf "\nBuilding inputfeeds_detection container\n"
docker build --tag inputfeeds_detection "docker containers/Input feeds from detectionAPI/."

printf "\nBuilding log parser container\n"
docker build --tag parse_dn_checksum "docker containers/Parse darknet logs/."