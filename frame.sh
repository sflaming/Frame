#!/usr/bin/env zsh

# Default values
DEFAULT_FRAME_COLOR="FFFFFF"
DEFAULT_RATIO="5:4"
MIN_MULTIPLIER=1.07
OUTPUT_DIR="./framed"
mkdir -p $OUTPUT_DIR

# Function to add uneven padding
pad_to_ratio() {
    local image_path=$1
    local frame_color=$2
    local ratio=${3}
    local web_resize=${4:-false}
    local ratio_x=${ratio%:*}
    local ratio_y=${ratio#*:}

    # Get original dimensions
    local original_width=$(sips -g pixelWidth $image_path | tail -n 1 | cut -d ' ' -f 4)
    local original_height=$(sips -g pixelHeight $image_path | tail -n 1 | cut -d ' ' -f 4)

    # Check if image can be resized to new ratio without cropping:
    local ratio_diff_landscape=`echo "scale=2; ( $ratio_x / $ratio_y ) - ( $original_width / $original_height )" | bc`
    local ratio_diff_portrait=`echo "scale=2; ( $ratio_y / $ratio_x ) - ( $original_width / $original_height )" | bc`

    echo "original width: $original_width"
    echo "original height: $original_height"
    echo "target ratio x: $ratio_x"
    echo "target ratio y: $ratio_y"
    echo "ratio diff landscape: $ratio_diff_landscape"
    echo "ratio diff portrait: $ratio_diff_portrait"

    local final_width final_height greatest 

    # Determine dimensions based on orientation
    if (( original_width > original_height )); then # Image orientation is Landscape
        if [[ $ratio_diff_landscape -gt 0 ]]; # Cropping required over 0. Mitigation required.
        then # Apply multiplier to short edge (height) instead. 
            echo "FR-1: Image is landscape... ratio is positive... so cropping would occur! Default multiplier added to height instead"
            final_height=$(( original_height * MIN_MULTIPLIER ))
            final_width=$(( final_height / ratio_y * ratio_x )) # swap the x and y ratios here to allow the frame orientation to match the image orientation
        else # use the original logic otherwise; use the multiplier on the width (the long edge), and calculate the height from that
            echo "FR-2: Image is landscape... ratio is negative... deafault behavior; multiplier added to width"
            final_width=$(( original_width * MIN_MULTIPLIER ))
            final_height=$(( final_width / ratio_x * ratio_y ))
        fi
        greatest=$original_width
    elif (( original_height > original_width )); then # Image orientation is Portrait
        if [[ $ratio_diff_portrait -lt 0 ]]; # if ratio_diff is NEGATIVE it can't be fully contained
        then # So use the MIN_MULTIPLIER on the width and calculate the height from that, swapping the x and y ratio
            echo "==> FR-3: Image is portrait... ratio is negative... so cropping would occur: flip x-er to non-deafault (short) edge: Width"
            final_width=$(( original_width * MIN_MULTIPLIER ))
            final_height=$(( final_width / ratio_y * ratio_x )) # swap the x and y ratios here to allow the frame orientation to match the image orientation
        else # use the multiplier on the height, and calculate the width from that
            echo "FR-4: Image is portrait... ratio is postitive... so use x-er on default (long) edge: Height"
            final_height=$(( original_height * MIN_MULTIPLIER ))
            final_width=$(( final_height / ratio_x * ratio_y))
        fi
        greatest=$original_height
    else # Square
        echo "FR-5: Image is a square, so use x-er on any edge: Height, for example"
        final_height=$(( original_height * MIN_MULTIPLIER ))
        final_width=$(( final_height / ratio_y * ratio_x )) # swap the x and y ratios here to allow the frame orientation to match the image orientation    
        greatest=$original_width
    fi
    echo "Final width: $final_width"
    echo "Final height: $final_height"

    # Construct the output filename
    local base_name=$(basename "${image_path%.*}")
    local output_file="${base_name}_${ratio%:*}-${ratio#*:}_padded"
    if [[ $frame_color != $DEFAULT_FRAME_COLOR ]]; then
        output_file="${output_file}_${frame_color}"
    fi
    if [[ $web_resize == true ]]; then
        output_file="${output_file}_web"
    fi
    output_file="${OUTPUT_DIR}/${output_file}.jpg"

    # Resize and pad image
    sips -Z $greatest -p $final_height $final_width --padColor $frame_color $image_path --out $output_file

    # Apply web resize if flag is set
    if [[ $web_resize == true ]]; then
        local temp_file="${output_file%.jpg}_temp.jpg"
        mv "$output_file" "$temp_file"
        
        # Get dimensions of framed image
        local framed_width=$(sips -g pixelWidth "$temp_file" | tail -n 1 | cut -d ' ' -f 4)
        local framed_height=$(sips -g pixelHeight "$temp_file" | tail -n 1 | cut -d ' ' -f 4)
        
        if (( framed_width > framed_height )); then
            # Landscape: resize to 1080px wide
            sips -Z 1080 "$temp_file" --out "$output_file"
        else
            # Portrait: resize to max 1350px tall
            sips -Z 1350 "$temp_file" --out "$output_file"
        fi
        rm "$temp_file"
    fi
}

# Parse command line arguments
web_resize=false
frame_color=$DEFAULT_FRAME_COLOR
ratio=$DEFAULT_RATIO

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--web)
            web_resize=true
            shift
            ;;
        -c|--color)
            frame_color=$2
            shift 2
            ;;
        -r|--ratio)
            ratio=$2
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 [-w|--web] [-c|--color COLOR] [-r|--ratio RATIO]"
            exit 1
            ;;
    esac
done

# Process all JPEG images
for file in *.[jJ][pP][gG]; do
    echo ""
    echo "Processing $file..."
    pad_to_ratio $file $frame_color $ratio $web_resize
    echo "$file processed with padding to $ratio."
done
