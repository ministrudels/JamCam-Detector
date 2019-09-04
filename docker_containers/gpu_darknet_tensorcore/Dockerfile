FROM nvidia/cuda:9.1-cudnn7-devel-ubuntu16.04

RUN apt-get update && apt-get install -y wget git && apt-get clean && rm -rf /var/cache/apt
RUN apt-get -y autoremove && apt-get -y autoclean
RUN rm -rf /var/cache/apt
RUN git clone https://github.com/AlexeyAB/darknet /darknet

WORKDIR /darknet
RUN sed -i s/GPU=0/GPU=1/g Makefile
RUN sed -i s/CUDNN=0/CUDNN=1/g Makefile
RUN sed -i s/CUDNN_HALF=0/CUDNN_HALF=1/g Makefile
RUN sed -i s/OPENMP=0/OPENMP=1/g Makefile
RUN make

# Download weights file
RUN wget https://pjreddie.com/media/files/yolov3.weights

# Run darknet
ENTRYPOINT ["./darknet", "detect", "cfg/yolov3.cfg", "yolov3.weights"]