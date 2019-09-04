import math
import sys
import requests
import yolo
from collections import defaultdict, Counter
from datetime import datetime, timezone

api_url = None

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
        db_object = {
            'id': camera,
            'checksum': checksum,
            'status': 'online',
            'datetime': datetime.utcnow().replace(tzinfo=timezone.utc).isoformat(),
            'detections': avg_detections}
        print('Inserting:', db_object)
        requests.post(api_url + 'insert_video_detection', json=db_object)
        all_frame_detections.pop(camera, None)

    return True


def main(argv):
    global api_url
    if argv[1] == 'local':
        api_url = "http://localhost:8080/TFLcamera/"
    if argv[1] == 'bucket':
        api_url = "https://jamcam-detections-api.appspot.com/TFLcamera/"

    detector = yolo.YOLO(argv[2])
    all_frame_detections = {}

    print('Begin detecting from', argv[2])
    while True:
        camera, checksum, detections = detector.get_detection()
        if not handle_detection(all_frame_detections, camera, checksum, detections):
            break

    print('Finished...')


if __name__ == "__main__":
    main(sys.argv)
