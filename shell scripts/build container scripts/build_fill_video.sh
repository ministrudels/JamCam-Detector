#!/usr/bin/env bash

printf "\nBuilding download videos container\n"
docker build --tag store_videos "docker containers/store videos/."
