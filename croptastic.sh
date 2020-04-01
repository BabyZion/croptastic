#!/usr/bin/bash

get_args(){
    while getopts ":v:g:o:f:W:H:B:T:hq" arg; do
        case "$arg" in
            v)
                type=0
                start_url="${OPTARG}"
                ;;
            g)
                type=1
                start_url="${OPTARG}"
                ;;
            h)
                help
                exit
                ;;
            o)
                output_f="${OPTARG}"
                ;;
            f)
                fps="${OPTARG}"
                ;;
            B)  
                begining="${OPTARG}"
                ;;
            T)
                time="${OPTARG}"
                ;;
            W)  
                width="${OPTARG}"
                let width="($width/2)*2"
                ;;
            H)  
                height="${OPTARG}"
                let height="($height/2)*2"
                ;;
            q)
                good_quality="no"
                ;;
            \?) 
                help
                exit
                ;;
        esac
    done

    if [[ $start_url == "" ]] || [[ $start_url == "-"[v,g,o,h,f,B,T,W,H,q] ]] || \
     [[ $output_f == "-"[v,g,o,h,f,B,T,W,H,q] ]] || [[ $fps == "-"[v,g,o,h,f,B,T,W,H,q] ]] || \
     [[ $scale == "-"[v,g,o,h,f,B,T,W,H,q] ]] || [[ $begining == "-"[v,g,o,h,f,B,T,W,H,q] ]] || \
     [[ $time == "-"[v,g,o,h,f,B,T,W,H,q] ]]; then
        echo ""
        echo "Bad parameters supplied."
        echo "Exiting"
        exit
    fi

    if [[ $begining != [0-5][0-9]":"[0-5][0-9] ]] || [[ $time != [0-5][0-9]":"[0-5][0-9] ]]; then
        echo "Wrong time format supplied."
        echo "Exiting"
        exit
    fi

}

help(){
    echo "Usage $(basename "$0") [OPTIONS] URL [URL...]:"
    echo ""
    echo "Gif Options:"
    echo "  -g              Create a .gif file from supplied URL."
    echo "  -f              FPS of output .gif file."
    echo "  -s              THe width of output .gif file."
    echo ""
    echo "Video Options:"
    echo "  -v              Create a .mp4 file from supplied URL."
    echo ""
    echo "General Options:"
    echo "  -o              Specifies output file for the .gif or .mp4 file."
    echo "  -h              Displays this window."
}

load_default_values(){
    if [[ $fps == "" ]]; then
        fps=24
    fi
    if [[ $width == "" ]] && [[ $height != "" ]]; then
        width=-2
    elif [[ $width != "" ]] && [[ $height == "" ]]; then
        height=-2
    elif [[ $width == "" ]] && [[ $height == "" ]]; then
        width=-2
        height=-2
    fi
    if [[ $output_f == "" ]]; then
        if [[ $type == 0 ]]; then
            output_f="$(date +"%Y-%m-%d_%H:%M:%S").mp4"
        else
            output_f="$(date +"%Y-%m-%d_%H:%M:%S").gif"
        fi
    fi
    if [[ $good_quality == "no" ]]; then
        color_pallet=""
    else
        color_pallet=":flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
    fi
}

get_urls(){
    # Get youtube-dl urls into array.
    # 0 - Video stream.
    # 1 - Audio stream.
    readarray -t urls <<<$(youtube-dl -g $start_url)
}

get_args $@
load_default_values

if [[ $start_url == *"://"* ]]; then
    online_link=true
    get_urls $start_url
else
    online_link=false
    urls[0]=$start_url
fi

# Video - works
# ffmpeg -ss 00:02 -i "${urls[0]}" -ss 00:02 -i "${urls[1]}" -map 0:v -map 1:a -ss 30 -t 01:00 -c:v libx264 -c:a aac test1.mp4 -y
# Without skipping from the start.
# ffmpeg -ss 00:00 -i "${urls[0]}" -ss 00:00 -i "${urls[1]}" -map 0:v -map 1:a -t 00:05 -c:v libx264 -c:a aac test5.mp4 -y
if [ $type == 0 ]; then
    if [ "$online_link" = true ]; then
        ffmpeg -ss $begining -i "${urls[0]}" -ss $begining -i "${urls[1]}" -map 0:v -map 1:a -t $time -r ${fps} -filter:v scale=${width}:${height} -c:v libx264 -c:a aac ${output_f} -y
    else
        ffmpeg -ss $begining -i "${urls[0]}" -ss $begining -i "${urls[0]}" -map 0:v -map 1:a -t $time -r ${fps} -filter:v scale=${width}:${height} -c:v libx264 -c:a aac ${output_f} -y
    fi
else
    # Gif -works
    ffmpeg -ss $begining -t $time -i "${urls[0]}" -vf "fps=${fps},scale=${width}:${height}:-1${color_pallet}" -loop 0 ${output_f} -y
fi
