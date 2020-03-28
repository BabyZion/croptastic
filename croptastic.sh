#!/usr/bin/bash

get_urls(){
    
    # Get youtube-dl urls into array.
    # 0 - Video stream.
    # 1 - Audio stream.
    readarray -t urls <<<$(youtube-dl -g $1)
    
}

fps=30
scale=500
output="test.mp4"

get_urls $1

# Video - works
ffmpeg -ss 03:02 -i "${urls[0]}" -ss 03:02 -i "${urls[1]}" -map 0:v -map 1:a -ss 30 -t 00:20 -c:v libx264 -c:a aac ${output} -y

# Gif -works
ffmpeg -ss 03:17 -t 00:16 -i "${urls[0]}" -vf "fps=${fps},scale=${scale}-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 ${output} -y


