#!/usr/bin/env bash

FILEPATHS=(/debug_pictures/base_images/*)

rm -rf /debug_pictures/initial /debug_pictures/thresh50 /debug_pictures/thresh10 /debug_pictures/thresh5
mkdir /debug_pictures/initial /debug_pictures/thresh50 /debug_pictures/thresh10 /debug_pictures/thresh5

for filepath in "${FILEPATHS[@]}"
    do
        filename=`basename "$filepath"`

        #Generate initial detections
        ./darknet detector test cfg/coco.data cfg/yolov3.cfg /weights/yolov3.weights ${filepath}
        mv predictions.jpg /debug_pictures/initial/${filename}

        #Generate detections with 50% thresholding
        ./darknet detector test cfg/coco.data cfg/yolov3.cfg /weights/yolov3.weights ${filepath} -thresh 0.5
        mv predictions.jpg /debug_pictures/thresh50/50${filename}

        #Generate detections with 10% thresholding
        ./darknet detector test cfg/coco.data cfg/yolov3.cfg /weights/yolov3.weights ${filepath} -thresh 0.1
        mv predictions.jpg /debug_pictures/thresh10/10${filename}

        #Generate detections with 5% thresholding
        ./darknet detector test cfg/coco.data cfg/yolov3.cfg /weights/yolov3.weights ${filepath} -thresh 0.05
        mv predictions.jpg /debug_pictures/thresh5/5${filename}

    done

