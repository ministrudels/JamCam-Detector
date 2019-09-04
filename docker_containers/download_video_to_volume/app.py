import os
import sys
import requests
import urllib.request


# Helper function
def get_checksum(camera):
    for property in camera['additionalProperties']:
        if property['key'] == 'videoUrl':
            return property['checksum']


# Main functions
def choose_feeds(checksums):
    result = []
    for checksum in checksums:
        r = requests.get("https://jamcam-detections-api.appspot.com/TFLcamera/video_details/" + checksum).json()
        result.append(r)
    return result


def download_video(camera, volume):

    mp4file = camera['checksum'] + '.mp4'
    mp4filepath = '/' + volume + '/' + mp4file

    # Download from gcloud url to file
    urllib.request.urlretrieve(camera['videoUrl'], mp4filepath)


def main(argv):
    volume = argv[1]
    video_checksums = argv[2:]

    print('Downloading videos', video_checksums, 'to', volume, 'volume')
    feeds = choose_feeds(video_checksums)
    for camera in feeds:
        download_video(camera, volume)
    os.mkdir('/' + volume + '/out')
    print('Finished...')


if __name__ == "__main__":
    main(sys.argv)
