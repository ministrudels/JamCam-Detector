# Description
This repository contains pipelines to obtain object detections on TfL JamCam feeds.
Running these pipelines accomplish:
 1) Downloading TfL videos and storing metadata to a MongoDB database
 2) Generate object detections and store detection data to a MongoDB database
 3) Serve this data through a REST API

The data generated may be used to get some cool insights from London's traffic cameras! Here a 
plot showing the level of cars in London over 3 days.

![](cars_London.gif)

# System Requirements
- Linux distribution - any which support  NVIDIA docker. See https://github.com/NVIDIA/nvidia-docker
- NVIDIA GPU

Install:
- Docker version 19.03.
- NVIDIA container toolkit. Follow the instructions here: https://github.com/NVIDIA/nvidia-docker



## Build the containers
To enable execute permissions on all files in shell scripts directory
```
chmod -R +x shell\ scripts/
``` 

Build pipeline containers 
``` 
./shell\ scripts/build_containers.sh 
```

In some cases, your GPU will need a different darknet images. If it has Tensor cores, change the image being used
to ```ganhuanmin/gpudarknet:tensor_core``` in the ```detect``` scripts. You can verify is you are using the right image
by viewing the log output of the running gpu_darknet container. If no output is being given, swap images.



## How to use locally: 
mp4 file named after its checksum are stored in ```~/TfL_videos``` directory on the host.
Metadata and Detections are stored in the MongoDB.


### 1. Prereqs
1) Setup the MongoDB database to run locally on default port 27017
2) Run simple file server making it available http://0.0.0.0:8000/
    1) cd to ```/``` directory. 
    2) ```python3 -m  http.server 8000``` - Run file server
3) Setup the REST API on the local machine:
    1) ```cd``` into detectionAPI
    2) ```virtualenv -p python3 env``` - Create python virtual environment
    3) ```source env/bin/activate``` - Start virtual environment
    4) ```pip install -r requirements.txt``` - Install requirements
    5) Exec ```python main.py``` to start the API
4) Run shell script which continually pings endpoint to update cached object
    1) ```cd``` into shell scripts and run ```scheduled_job_on_local_API.sh```


### 2. Fill video store indefinitely
1) Run fill_video_store_local.sh script ``` ./shell\ scripts/deploy\ local\ scripts/fill_video_store_local.sh ``` which 
  will query the TFL api and add it download the video and create metadata

### 3. Detect on video store indefinitely
1) Run ```detect_on_JamCam_detections_API_local.sh```. Note this DOES NOT detect every video in the store, 
but rather every 20 or so minutes. It is limited by detector speed and cannot ping the internal API quick 
enough to get all videos. If darknet is not outputting any detections (you can check with ```docker logs -f gpu_darknet```), 
try using the other gpudarknet image.

### 4. Get freshest videos and detections
1) ```fill_detect_once.sh``` - Get freshest feeds from TFL and perform detections on them



## How to use on the cloud:
mp4 file named after its checksum are stored in ```~/tfl-mp4-videos``` bucket in GCP.
Metadata and Detections are stored in MongoDB

### 1. Prereqs
1) Setup the MongoDB database and get its connection URL
2) Change the Mongo connection URL in detectionAPI/config.py
3) Setup the REST API on the local machine:
    1) ```cd detectionAPI```
    2) ```gcloud config set project jamcam-detections-api``` - Set the Google cloud project to deploy to its app engine
    3) ```gcloud app deploy``` - Deploy the API, takes several minutes
    4) ```gcloud app deploy cron.yaml``` - Deploy scheduled cron job to update cached response object

### 2. Fill video store indefinitely
1) Run fill_video_store_bucket.sh script ``` ./shell\ scripts/deploy\ cloud\ scripts/fill_video_store_bucket.sh ``` which 
  will query the TFL api and add it download the video and create metadata

### 3. Detect on video store indefinitely
1) Run ```detect_on_JamCam_detections_API_bucket.sh```. Note this DOES NOT detect every video in the store, 
but rather every 20 or so minutes. It is limited by detector speed and cannot ping the internal API quick 
enough to get all videos. If darknet is not outputting any detections (you can check with ```docker logs -f gpu_darknet```), 
try using the other gpudarknet image.

### 4. Get freshest videos and detections
1) ```fill_detect_once.sh``` - Get freshest feeds from TFL and perform detections on them


## Other pipelines
To generate the jpg detections of all images within a directory, run 
```
docker run --rm -d --name debug -it --mount type=bind,source="$(pwd)"/debug_pictures,target=/debug_pictures --entrypoint "/bin/bash" output_detected_video
docker cp shell\ scripts/Scripts\ for\ debugging/improving_darknet.sh debug:/darknet/ 
docker attach debug
./improving_darknet.sh
```

To generate detections of all the videos in a database, run
```
detect_all_videos.sh
```

To run the debug mp4 pipeline, run. Exit the container when finished and the results will be in subdirectories in debug_pictures
```
create_debug_mp4s.sh
```

### Containers
```download_video_to_volume``` Download a JamCam video to the specified volume

```gpu_darknet``` YOLO darknet container for accelerated gpu computation 

```gpu_darknet_tensorcore``` YOLO darknet container for accelerated gpu computation for GPUs with tensor cores

```input_from_API``` Send input to darknet container from deployed detectionAPI

```input_from_db``` Send input to darknet container from database

```output_detected_video``` Create a detected version of a video

```parse_dn_logs``` Receive input from STDOUT of darknet container and send detections to API

```parse_dn_db``` Receive input from STDOUT of darknet container and send detections to database

```store_videos``` Sole container for pipeline to download videos and store them into a database

```upload_video``` Upload the videos from target directory

# Licensing
Uses public sector information licensed under the Open Government Licence v3.0.