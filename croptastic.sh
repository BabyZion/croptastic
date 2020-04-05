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
                if [[ $output_f != *".mp4" || $output_f != *".gif" ]]; then
                    if [[ $type == 0 ]]; then
                        output_f=$output_f".mp4"
                    else
                        output_f=$output_f".gif"
                    fi
                fi
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

    arg_type="switch"
    for i in $@
    do
        if [[ $arg_type == "switch" ]]; then
            if [[ $i == "-"[A-Za-z] ]] && [[ $i != "-"[q,h] ]]; then
                arg_type="arg"
            elif [[ $i == "-"[q,h] ]]; then
                arg_type="switch"
            else
                echo "Bad parameters supplied."
                echo "Exiting"
                exit
            fi
        elif [[ $arg_type == "arg" ]]; then
            if [[ $i != "-"[A-Za-z] ]]; then
                arg_type="switch"
            else
                echo "Bad parameters supplied."
                echo "Exiting"
                exit
            fi
        fi
    done
    if [[ $arg_type == "arg" ]] && [[ ${@: -1} != "-"[q,h] ]]; then
        echo "Bad parameters supplied."
        echo "Exiting"
        exit
    fi

    if [[ $start_url == "" ]]; then
        echo ""
        echo "Input URL not supplied."
        echo "Exiting"
        exit
    fi

    declare -a formats=([0-5][0-9]":"[0-5][0-9] [0-5][0-9]":"[0-5][0-9]"."[0-9][0-9][0-9] [0-2][0-9]":"[0-5][0-9]":"[0-5][0-9] [0-2][0-9]":"[0-5][0-9]":"[0-5][0-9]"."[0-9][0-9][0-9])

    good_format=false
    for i in {0..3}
    do
        if [[ $begining == ${formats[i]} && $time == ${formats[i]} ]]; then
            good_format=true
            break
        fi
    done
    if [[ $good_format == false ]]; then
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
        crf=30
    else
        color_pallet=":flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
        crf=23
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
    get_urls $start_url
    if [[ ${urls[1]} == "" ]]; then
        urls[1]=${urls[0]}
    fi
else
    urls[0]=$start_url
    urls[1]=${urls[0]}
fi

if [ $type == 0 ]; then
    ffmpeg -ss $begining -i "${urls[0]}" -ss $begining -i "${urls[1]}" -map 0:v -map 1:a -t $time -r ${fps} -filter:v scale=${width}:${height} -c:v libx264 -crf ${crf} -c:a aac ${output_f} -y
else
    ffmpeg -ss $begining -t $time -i "${urls[0]}" -vf "fps=${fps},scale=${width}:${height}:-1${color_pallet}" -loop 0 ${output_f} -y
fi
