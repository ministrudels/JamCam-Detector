import docker
import re

from collections import defaultdict

client = docker.from_env()
low_client = docker.APIClient(timeout=60) #10 minute timeout


# Wrapper for darknet container
class YOLO:

    # private
    # Set private container variable to be darknet container
    def get_container (self, name=None):
        all_containers = low_client.containers()
        for container in all_containers:
            if container['Names'][0] == '/' + name:
                gpu_container = client.containers.get(name)
                return gpu_container
        return None

    # Set private log stream variable and preprocess initialisation
    def preparse_logs (self):
        line = ''
        for byte_stream in self.log_stream:
            character = byte_stream.decode("utf-8")
            line += character
            if line == 'Loading weights from yolov3.weights...Done!':
                break
            if line == 'Done!':
                break
            if character == "\n":
                line = ''
                continue

    def isStdIn (self, line):
        return 'JamCams' in line

    def containsSpecialChar (self, first_word):
        regex = re.compile('[@_!#$%^&*()<>?/\|}{~:.]')
        if regex.search(first_word) is None:
            return False
        else:
            return True

    def linebreak (self, character):
        return character is '\n'


    def apply_thresholding (self, object, confidence):
        confidence = int(''.join(e for e in confidence if e.isalnum()))

        if object == 'truck' and confidence < 25:
            return 0
        if object == 'van' and confidence < 10:
            return 0
        if object == 'car' and confidence < 10:
            return 0
        return 1


    # public
    def __init__ (self, image_name):
        self.container = self.get_container(image_name)
        self.log_stream = low_client.logs(self.container.id, stream=True, follow=True)
        self.preparse_logs()
        self.stdin_socket = low_client.attach_socket(self.container.id, params={'stdin': 1, 'stream': 1})
        self.stdin_socket._writing = True

    # Queue an image for darknet
    def input (self, filepath):
        self.stdin_socket.write(filepath.encode('utf-8'))
        # s.close()

    # Get next detection from darknet
    def get_detection (self):
        camera = ''
        checksum = ''
        line = ''
        detections = defaultdict(int)

        # Go through all the bullshit in logs until find ":Predicted in"
        for byte_stream in self.log_stream:
            character = byte_stream.decode("utf-8")
            line += character
            if self.linebreak(character):
                if ': Predicted in' in line:
                    img_path = line.partition(': Predicted in')[0]
                    checksum = img_path.split('/')[-2]
                    camera = img_path.split('/')[-3]
                    break
                line = ''

        # Detection output is here
        line = ''
        for byte_stream in self.log_stream:
            character = byte_stream.decode("utf-8")
            line += character
            # End of detection
            if 'Enter' in line:
                break

            # If contains a linebreak character:
            if self.linebreak(character):
                first_word = line.partition(':')[0]
                confidence = line.partition(':')[2]
                if self.isStdIn(line):
                    continue
                if self.containsSpecialChar(first_word):
                    continue
                detections[first_word] += self.apply_thresholding(first_word, confidence)
                line = ''

        return camera, checksum, detections



