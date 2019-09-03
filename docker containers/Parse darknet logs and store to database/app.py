import math
import sys
import yolo
from collections import defaultdict, Counter
from pymongo import MongoClient

db_client = MongoClient(
    "mongodb+srv://TFLcams:dotflcams@cluster0-tqcsp.gcp.mongodb.net/test?retryWrites=true&w=majority")
db = db_client.test
video_collection = db.TfLvideos
detection_collection = db.TfLvideos_detections


def handle_detection(all_frame_detections, camera, checksum, detections):
    # If socket to container is closed , exit
    if camera == '':
        print('Timeout on reading the log stream reached!')
        return False

    # Begin collecting all frame detections for the camera if camera not seen yet
    if camera not in all_frame_detections:
        all_frame_detections[camera] = {
            'frames': 0,
            'detections': defaultdict(int)
        }

    # Add the detection
    all_frame_detections[camera]['detections'] = dict(
        Counter(all_frame_detections[camera]['detections']) + Counter(detections))
    all_frame_detections[camera]['frames'] += 1

    # If 8 detections obtained, then average
    if all_frame_detections[camera]['frames'] == 8:
        avg_detections = {}
        for key in all_frame_detections[camera]['detections']:
            avg_detections[key] = math.ceil(all_frame_detections[camera]['detections'][key] / 8)
        video = video_collection.find({'checksum': checksum}).next()
        db_object = {
            "id": video['id'],
            "checksum": video['checksum'],
            "status": "online",
            "datetime": video['datetime'],
            "detections": avg_detections}
        detection_collection.insert_one(db_object)
        all_frame_detections.pop(camera, None)

    return True


def main(argv):
    detector = yolo.YOLO(argv[1])
    all_frame_detections = {}

    print('Begin detecting from', argv[1])
    while True:
        camera, checksum, detections = detector.get_detection()
        if not handle_detection(all_frame_detections, camera, checksum, detections):
            break

    print('Finished...')


if __name__ == "__main__":
    main(sys.argv)
