# Description
This repository contains pipelines to obtain object detections on TfL JamCam feeds.
Running these pipelines accomplish:
 1) Downloading TfL videos and storing metadata to a MongoDB database
 2) Generate object detections and store detection data to a MongoDB database
 3) Serve this data through a REST API


# System Requirements
- Linux distribution - any which support  NVIDIA docker. See for more https://github.com/NVIDIA/nvidia-docker
info
- Docker version 19.03
- NVIDIA GPU


# Building the containers for
1) ```chmod -R +x shell\ scripts/``` - To enable execute permissions on all files in shell scripts directory
2) Build pipeline containers ``` ./shell\ scripts/build\ container\ scripts/build_containers.sh ```
3) In some cases, your GPU will need a different darknet images. If it has Tensor cores, change the image being used
   to ```ganhuanmin/gpudarknet:tensor_core``` in the ```detect``` scripts. You can verify is you are using the right image
   by viewing the log output of the running gpu_darknet container.



# How to use locally: 
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



# How to use on the cloud:
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
1) Run fill_video_store_local.sh script ``` ./shell\ scripts/deploy\ cloud\ scripts/fill_video_store_bucket.sh ``` which 
  will query the TFL api and add it download the video and create metadata

### 3. Detect on video store indefinitely
1) Run ```detect_on_JamCam_detections_API_bucket.sh```. Note this DOES NOT detect every video in the store, 
but rather every 20 or so minutes. It is limited by detector speed and cannot ping the internal API quick 
enough to get all videos. If darknet is not outputting any detections (you can check with ```docker logs -f gpu_darknet```), 
try using the other gpudarknet image.

### 4. Get freshest videos and detections
1) ```fill_detect_once.sh``` - Get freshest feeds from TFL and perform detections on them


# Miscelaneous

## Utility scripts
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

To run the debug mp4 pipeline, run
```
create_debug_mp4s.sh
```

Exit the container when finished and the results will be i subdirectories in debug_pictures



##### Build scripts
```build_fill_video.sh``` - Build containers for fill video script

```build_detect_on_JamCam.sh``` - Build containers for detect script

```build_create_debug_mp4s.sh``` - Build containers for create detected versions of TfL videos 

##### Deploy pipeline scripts
```fill_video_store.sh``` - Download TfL videos to GCS bucket and store checksum in DB

```detect_on_TfL_API.sh``` - Run the live pipeline on a GPU machine on the TfLAPI

```detect_on_JamCam_detections_API.sh``` - Run the live pipeline on a GPU machine on the detectionAPI 

```create_debug_mp4s.sh``` - Create detected versions of TfL videos and store them on GCS


##### Containers
```cpu_darknet``` - darknet container for cpu computation
```gpu_darknet``` - darknet container for accelerated gpu computation
```download_videos``` - Run on any machine. Downloads videos from TFL API and stores them in GCS
```Input feeds once from *``` - Container to input feeds to a specified darknet container
```output_detected_video``` - Create a detected version of a video
```Parse darknet logs once ``` - Parse the logs of darknet container to extract the detections
TODO:describe more containers

##### Databases
The TfLvideos database contains video details, including the video's checksum, and approximate datetime
The videoDetections database contains the detections of each video

# Licensing
Uses public sector information licensed under the Open Government Licence v3.0.