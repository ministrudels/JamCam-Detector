
# ffmpeg -i cars/normalised.m4v -i trucks/normalised.m4v -i persons/normalised.m4v -i cars/normalised_central.m4v -i trucks/normalised_central.m4v -i persons/normalised_central.m4v -filter_complex "[0:v][1:v][2:v][3:v][4:v][5:v]xstack=inputs=6:layout=0_0|w0_0|w0+w1_0|0_h0|w0_h1|w0+w1_h2" -map v normalised_all.m4v
# ffmpeg -i cars/raw.m4v -i trucks/raw.m4v -i persons/raw.m4v -i cars/raw_central.m4v -i trucks/raw_central.m4v -i persons/raw_central.m4v -i truck.png -filter_complex "[0:v][1:v][2:v][3:v][4:v][5:v]xstack=inputs=6:layout=0_0|w0_0|w0+w1_0|0_h0|w0_h1|w0+w1_h2" -map v raw_all.m4v


ffmpeg -i normalised_all.m4v -i car.png -i truck.png -i person.png -filter_complex "[0:v][1:v] overlay=960:1940 [tmp1], [tmp1][2:v] overlay=2880:1920 [tmp2], [tmp2][3:v] overlay=4800:1940" -map v tmp_normalised_all.m4v
ffmpeg -i raw_all.m4v -i car.png -i truck.png -i person.png -filter_complex "[0:v][1:v] overlay=960:1940 [tmp1], [tmp1][2:v] overlay=2880:1920 [tmp2], [tmp2][3:v] overlay=4800:1940" -map v tmp_raw_all.m4v


ffmpeg -y -i tmp_normalised_all.m4v -vf \
"drawbox=x=0:y=0:w=4800:h=380:color=#FFFFE3@1:t=fill, \
drawbox=1910:0:20:3840:#FFFFE3@1:t=fill, \
drawbox=3830:0:20:3840:#FFFFE3@1:t=fill, \
drawbox=0:0:20:3840:#FFFFE3@1:t=fill, \
drawbox=5740:0:20:3840:#FFFFE3@1:t=fill, \
drawtext=fontsize=100:fontfile=FreeSerif.ttf:text='Level of objects in London, UK':x=(w-text_w)/2:y=150" final_n_all.mp4
ffmpeg -y -i tmp_raw_all.m4v -vf \
"drawbox=x=0:y=0:w=4800:h=380:color=#FFFFE3@1:t=fill, \
drawbox=1910:0:20:3840:#FFFFE3@1:t=fill, \
drawbox=3830:0:20:3840:#FFFFE3@1:t=fill, \
drawbox=0:0:20:3840:#FFFFE3@1:t=fill, \
drawbox=5740:0:20:3840:#FFFFE3@1:t=fill, \
drawtext=fontsize=100:fontfile=FreeSerif.ttf:text='Count of objects in London, UK':x=(w-text_w)/2:y=150" final_r_all.mp4


ffmpeg -i final_n_all.mp4 -vf eq=brightness=0.05:saturation=1.4 -c:a copy final_n_all1.mp4
ffmpeg -i final_r_all.mp4 -vf eq=brightness=0.05:saturation=1.4 -c:a copy final_r_all1.mp4
