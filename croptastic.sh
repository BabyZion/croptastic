#!/usr/bin/bash

get_urls(){
    
    # Get youtube-dl urls into array.
    # 0 - Video stream.
    # 1 - Audio stream.
    readarray -t urls <<<$(youtube-dl -g $1)
    
}

if [[ $1 == *"://"* ]]; then
    online_link=true
    get_urls $1
else
    online_link=false
    urls[0]=$1
fi

fps=30
scale=500
output="test.mp4"

# Video - works
# ffmpeg -ss 00:02 -i "${urls[0]}" -ss 00:02 -i "${urls[1]}" -map 0:v -map 1:a -ss 30 -t 01:00 -c:v libx264 -c:a aac test1.mp4 -y
# Without skipping from the start.
# ffmpeg -ss 00:00 -i "${urls[0]}" -ss 00:00 -i "${urls[1]}" -map 0:v -map 1:a -t 00:05 -c:v libx264 -c:a aac test5.mp4 -y
if [ "$online_link" = true ]; then
    ffmpeg -ss 00:00 -i "${urls[0]}" -ss 00:00 -i "${urls[1]}" -map 0:v -map 1:a -t 00:05 -c:v libx264 -c:a aac test5.mp4 -y
else
    ffmpeg -ss 00:00 -i "${urls[0]}" -ss 00:00 -i "${urls[0]}" -map 0:v -map 1:a -t 00:05 -c:v libx264 -c:a aac test5.mp4 -y
fi

# Gif -works
ffmpeg -ss 00:00 -t 00:05 -i "${urls[0]}" -vf "fps=${fps},scale=${scale}:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 gif_test.gif -y


