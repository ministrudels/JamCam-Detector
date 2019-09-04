#!/usr/bin/env bash

printf "\nBuilding inputfeeds_detection container\n"
docker build --tag inputfeeds_detection "docker_containers/input_from_API/."

printf "\nBuilding log parser container\n"
docker build --tag parse_dn_checksum "docker_containers/parse_dn_logs/."
