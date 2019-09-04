import sys
import requests
from google.cloud import storage
from os import listdir

storage_client = storage.Client()


def main(argv):
    folder = argv[1]
    bucket = storage_client.get_bucket('tfl-mp4-videos')
    files = listdir('..' + folder)

    print('Uploading videos from', folder)
    for file in files:

        # Upload file to GCP bucket
        blob_name = 'debug' + file
        blob = bucket.blob(blob_name)
        blob.upload_from_filename(folder + '/' + file)

        # Update the object in Mongo
        checksum = file.replace('.avi', '')
        args = {'checksum': checksum, 'debug_url': blob.media_link}
        requests.get("https://jamcam-detections-api.appspot.com/TFLcamera/video_details/update", args)
        print('Uploaded video', blob_name, 'available at', blob.media_link)
    print('Finished...')


if __name__ == "__main__":
    main(sys.argv)
