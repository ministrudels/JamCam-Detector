import os
import sys
import requests
import hashlib
import urllib.request
from google.cloud import storage
from datetime import datetime, timezone


def choose_feeds(lower, upper):
    r = requests.get("https://api.tfl.gov.uk/Place/Type/JamCam").json()
    return r[lower:upper]


def get_md5_hash(mp4url):
    hasher = hashlib.md5()
    data = urllib.request.urlopen(mp4url)
    hasher.update(data.read())
    return hasher


def get_mp4_url(camera):
    mp4url = None
    for property in camera['additionalProperties']:
        if property['key'] == 'videoUrl':
            mp4url = property['value']
    return mp4url


class Downloader:
    def __init__(self, dltype):
        self.dltype = dltype
        self.bucket = None
        self.api_url = None
        self.folder = '/TfL_videos/'

        if not os.path.exists(self.folder):
            os.mkdir(self.folder)

        if dltype == 'local':
            self.api_url = "http://localhost:8080/TFLcamera/"
            if not os.path.exists(self.folder):
                os.mkdir(self.folder)

        if dltype == 'bucket':
            storage_client = storage.Client()
            self.bucket = storage_client.get_bucket('tfl-mp4-videos')
            self.api_url = "https://jamcam-detections-api.appspot.com/TFLcamera/"

    def store_video(self, camera, md5hash, dt):
        id = camera['id']
        datetime = dt
        checksum = md5hash.hexdigest()
        videoUrl = None
        downloadUrl = get_mp4_url(camera)

        checksum_exists = requests.get(self.api_url + "checksum_exists/" + checksum).json()['result']
        if checksum_exists:
            print('already exists', checksum)
            return 0
        else:
            print('adding', checksum)

            # Download to container storage
            mp4file = checksum + '.mp4'
            filepath = self.folder + mp4file
            urllib.request.urlretrieve(downloadUrl, filepath)

            if self.dltype == 'local':
                videoUrl = 'http://0.0.0.0:8000' + filepath

            if self.dltype == 'bucket':
                blob = self.bucket.blob(checksum + '.mp4')
                blob.upload_from_filename(filepath)
                videoUrl = blob.media_link

            args = {
                'id': id,
                'datetime': datetime,
                'checksum': checksum,
                'videoUrl': videoUrl
            }
            requests.get(self.api_url + 'video_details/insert', args)
            return 1


def main(argv):
    current_dt = datetime.utcnow().replace(tzinfo=timezone.utc).isoformat()
    print('Downloading latest videos at', current_dt)
    feeds = choose_feeds(int(argv[2]), int(argv[3]))

    # Create downloader object
    downloader = Downloader(argv[1])
    videos_downloaded = 0
    for camera in feeds:
        mp4url = get_mp4_url(camera)
        md5hash = get_md5_hash(mp4url)
        videos_downloaded += downloader.store_video(camera, md5hash, current_dt)
        sys.stdout.flush()
    print('New videos downloaded:', videos_downloaded)


if __name__ == "__main__":
    main(sys.argv)
