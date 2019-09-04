import os
import shutil
import sys
import cv2
import requests
import urllib.request
import yolo

from datetime import datetime, timezone

api_url = None


# Helper function
def get_checksum(camera):
    for property in camera['additionalProperties']:
        if property['key'] == 'videoUrl':
            return property['checksum']


def get_mp4_url(camera):
    mp4url = None
    for property in camera['additionalProperties']:
        if property['key'] == 'videoUrl':
            mp4url = property['value']
    return mp4url


# Main functions
def choose_feeds(lower, upper):
    r = requests.get(api_url + "JamCam").json()
    return r[lower:upper]


def download_video(camera):
    # Set values
    video_checksum = get_checksum(camera)
    camera_folder = '/TfLfeeds/' + camera['id']
    video_folder = camera_folder + '/' + video_checksum
    mp4file = video_checksum + '.mp4'
    mp4filepath = video_folder + '/' + mp4file

    # Create the folder to store the video
    if os.path.exists(video_folder):
        shutil.rmtree(video_folder)
    os.mkdir(camera_folder)
    os.mkdir(video_folder)

    # Downlaod the video
    mp4url = get_mp4_url(camera)
    urllib.request.urlretrieve(mp4url, mp4filepath)

    return cv2.VideoCapture(mp4filepath), video_folder


def get_frames(vidObj, video_folder):
    frameNumbers = [0, 24, 49, 99, 124, 149, 174, 199]
    frames = []

    for i in frameNumbers:
        vidObj.set(cv2.CAP_PROP_POS_FRAMES, i)
        success, image = vidObj.read()
        filepath = video_folder + '/' + "frame%d.jpg" % (i + 1)
        if image is None:
            return []
        cv2.imwrite(filepath, image)
        frames.append(filepath)
    return frames


def input_frames(frames, camera, detector):
    if not len(frames):
        # Input camera is offline information
        print(camera['id'], 'is offline!')
        db_object = {
            'id': camera['id'],
            'checksum': get_checksum(camera),
            'status': 'offline',
            'datetime': datetime.utcnow().replace(tzinfo=timezone.utc).isoformat()
        }
        requests.post(api_url + 'insert_video_detection', json=db_object)
    else:
        print(camera['id'], 'is online being sent for detection...')
        for frame in frames:
            detector.input(frame + '\n')


def main(argv):
    global api_url
    if argv[1] == 'local':
        api_url = "http://localhost:8080/TFLcamera/"
    if argv[1] == 'bucket':
        api_url = "https://jamcam-detections-api.appspot.com/TFLcamera/"

    detector = yolo.YOLO(argv[2])
    print('Getting latest feed as of ', datetime.utcnow().replace(tzinfo=timezone.utc).isoformat(), 'from', argv[3], argv[4])
    feeds = choose_feeds(int(argv[3]), int(argv[4]))
    for camera in feeds:
        checksum = get_checksum(camera)
        if checksum:
            checksum_exists = requests.get(api_url + "checksum_detection_exists/" + checksum).json()['result']
            if checksum_exists:
                print('Video detection for video: ', checksum, 'already exists!')
                continue
            vidObj, video_folder = download_video(camera)
            frames = get_frames(vidObj, video_folder)
            input_frames(frames, camera, detector)
    print('Finished...')


if __name__ == "__main__":
    main(sys.argv)
