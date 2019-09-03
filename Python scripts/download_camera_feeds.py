import os
import pprint

import requests
import urllib.request
import sys

if __name__== "__main__":

    if(len(sys.argv) > 1):
        id = sys.argv[1]

    r = requests.get("https://api.tfl.gov.uk/Place/Type/JamCam")
    response = r.json()

    os.mkdir('TFL_pictures')
    os.mkdir('./TFL_videos/')

    for camera in response:
        # print(pprint.pprint(camera))

        url = camera['additionalProperties'][1]['value']
        print('Downloading from ' + url + '............')
        urllib.request.urlretrieve(url, './TFL_pictures/' + camera['id'] + '.jpg')
        url = camera['additionalProperties'][2]['value']
        print('Downloading from ' + url + '............')
        urllib.request.urlretrieve(url, './TFL_videos/' + camera['id'] + '.mp4')

    print('Finished')

