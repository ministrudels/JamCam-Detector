import os
import shutil
import sys
import cv2
import urllib.request
import yolo

from pymongo import MongoClient

db_client = MongoClient(
    "mongodb+srv://TFLcams:dotflcams@cluster0-tqcsp.gcp.mongodb.net/test?retryWrites=true&w=majority")
db = db_client.test
video_collection = db.TfLvideos
detection_collection = db.TfLvideos_detections


def download_video(video):
    # Set values
    video_checksum = video['checksum']
    camera_folder = '/TfLfeeds/' + video['id']
    video_folder = camera_folder + '/' + video_checksum
    mp4file = video_checksum + '.mp4'
    mp4filepath = video_folder + '/' + mp4file

    # Create the folder to store the video
    if os.path.exists(video_folder):
        shutil.rmtree(video_folder)
    os.mkdir(video_folder)

    # Download the video
    mp4url = video['videoUrl']
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


def input_frames(frames, video, detector):
    if not len(frames):
        # print(video['checksum'], 'is offline at', video['datetime'])
        detection_collection.insert_one({
            "id": video['id'],
            "checksum": video['checksum'],
            "status": "offline",
            "datetime": video['datetime']})
    else:
        # print(video['checksum'], 'is online at', video['datetime'], 'being sent for detection...')
        for frame in frames:
            detector.input(frame + '\n')


def main(argv):
    print(video_collection.count_documents({}))
    # Per camera basis
    detector = yolo.YOLO(argv[1])
    camera = argv[2]

    # Get videos of the camera from database
    videos = list(video_collection.find({'id': camera}))
    number_of_videos = len(videos)
    print('There are ', number_of_videos, 'videos for', camera)

    counter = 0

    # Make the folder
    camera_folder = '/TfLfeeds/' + camera
    if os.path.exists(camera_folder):
        shutil.rmtree(camera_folder)
    os.mkdir(camera_folder)

    for video in videos:
        vidObj, video_folder = download_video(video)
        frames = get_frames(vidObj, video_folder)
        input_frames(frames, video, detector)
        counter += 1
        print('Handled', counter)

if __name__ == "__main__":
    main(sys.argv)
