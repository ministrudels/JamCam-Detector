#!/usr/bin/env bash

printf "\nBuilding inputfeeds_detection container\n"
docker build --tag inputfeeds_detection "docker containers/Input feeds from detectionAPI/."

printf "\nBuilding log parser container\n"
docker build --tag parse_dn_checksum "docker containers/Parse darknet logs/."
