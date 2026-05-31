#!/usr/bin/env zsh

# Default values
DEFAULT_FRAME_COLOR="FFFFFF"
DEFAULT_RATIO="5:4"
MIN_MULTIPLIER=1.07

# Function to add uneven padding
pad_to_ratio() {
    local image_path=$1
    local frame_color=$2
    local ratio=${3}
    local web_resize=${4:-false}
    local ratio_x=${ratio%:*}
    local ratio_y=${ratio#*:}

    # Create framed directory in the same location as the image
    local image_dir=$(dirname "$image_path")
    local OUTPUT_DIR="${image_dir}/framed"
    mkdir -p "$OUTPUT_DIR"

    # Get original dimensions
    local original_width=$(sips -g pixelWidth "$image_path" | tail -n 1 | cut -d ' ' -f 4)
    local original_height=$(sips -g pixelHeight "$image_path" | tail -n 1 | cut -d ' ' -f 4)

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
            echo "FR-3: Image is portrait... ratio is negative... so cropping would occur: flip x-er to non-deafault (short) edge: Width"
            echo "FR-3: Image is portrait... ratio is negative... so cropping would occur: flip x-er to non-deafault (short) edge: Width"
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

    # Resize and pad image, then resave with original size if flag set
    sips -Z $greatest -p $final_height $final_width --padColor $frame_color "$image_path" --out "$output_file"
    if [[ $reset_size == true ]]; then
        sips -Z $greatest "$output_file" --out "$output_file"
    fi

    # Apply web resize if flag is set
    if [[ $web_resize == true ]]; then
        local temp_file="${output_file%.jpg}_temp.jpg"
        mv "$output_file" "$temp_file"
        
        # Get dimensions of framed image
        local framed_width=$final_width
        local framed_height=$final_height
        # local framed_width=$(sips -g pixelWidth "$temp_file" | tail -n 1 | cut -d ' ' -f 4)
        # local framed_height=$(sips -g pixelHeight "$temp_file" | tail -n 1 | cut -d ' ' -f 4)
        
        if (( framed_width > framed_height )); then
            # Landscape: resize to 1080px wide
            sips -Z 1080 -s format jpeg -s formatOptions 100 "$temp_file" --out "$output_file" 
        else
            # Portrait: resize to max 1350px tall
            sips -Z 1350 -s format jpeg -s formatOptions 100 "$temp_file"  --out "$output_file" 
        fi
        rm "$temp_file"
    fi
}

pad_uniformly() {
    local image_path=$1
    local frame_color=$2
    local web_resize=${3:-false}
    # 'reset_size' is a global variable and will be accessed directly

    local image_dir=$(dirname "$image_path")
    local OUTPUT_DIR="${image_dir}/framed"
    mkdir -p "$OUTPUT_DIR"

    local original_width=$(sips -g pixelWidth "$image_path" | tail -n 1 | cut -d ' ' -f 4)
    local original_height=$(sips -g pixelHeight "$image_path" | tail -n 1 | cut -d ' ' -f 4)

    # Determine the shorter side
    local shorter_side=$original_width
    if (( original_height < original_width )); then
        shorter_side=$original_height
    fi

    # Calculate the padding amount based on the shorter side and MIN_MULTIPLIER
    # (MIN_MULTIPLIER - 1.0) gives the fractional increase (e.g., 0.07 for 1.07)
    local padding_factor=$(echo "$MIN_MULTIPLIER - 1.0" | bc -l)
    local border_padding_value=$(echo "($shorter_side * 0.4) * $padding_factor" | bc -l | awk '{print int($1+0.5)}')

    # Calculate final dimensions by adding the padding to both sides of width and height
    local final_width=$((original_width + (2 * border_padding_value)))
    local final_height=$((original_height + (2 * border_padding_value)))

    echo "Original width: $original_width, Original height: $original_height"
    echo "Shorter side: $shorter_side, Border padding value (each side): $border_padding_value"
    echo "Uniform padding target width: $final_width, Uniform padding target height: $final_height"

    local base_name=$(basename "${image_path%.*}")
    local output_file="${base_name}_uniform_padded"
    if [[ $frame_color != $DEFAULT_FRAME_COLOR ]]; then
        output_file="${output_file}_${frame_color}"
    fi
    if [[ $web_resize == true ]]; then
        output_file="${output_file}_web"
    fi
    output_file="${OUTPUT_DIR}/${output_file}.jpg"

    sips -p $final_height $final_width --padColor $frame_color "$image_path" --out "$output_file"

    if [[ $reset_size == true ]]; then
        local original_greatest_dim=$original_width
        if (( original_height > original_width )); then
            original_greatest_dim=$original_height
        fi
        echo "Resetting size to greatest original dimension: $original_greatest_dim"
        sips -Z $original_greatest_dim "$output_file" --out "$output_file"
    fi

    if [[ $web_resize == true ]]; then
        local temp_file="${output_file%.jpg}_temp.jpg"
        mv "$output_file" "$temp_file"
        
        # Get dimensions of the newly padded image for web resize logic
        local padded_width=$(sips -g pixelWidth "$temp_file" | tail -n 1 | cut -d ' ' -f 4)
        local padded_height=$(sips -g pixelHeight "$temp_file" | tail -n 1 | cut -d ' ' -f 4)
        
        if (( padded_width > padded_height )); then
            # Landscape: resize to 1080px wide
            sips -Z 1080 -s format jpeg -s formatOptions 100 "$temp_file" --out "$output_file" 
        else
            # Portrait: resize to max 1350px tall
            sips -Z 1350 -s format jpeg -s formatOptions 100 "$temp_file"  --out "$output_file" 
        fi
        rm "$temp_file"
    fi
    echo "Uniformly padded image saved to $output_file"
}

# Function to check if a file is an image
is_image() {
    local file="$1"
    # Use sips to check if it's an image (more reliable for macOS)
    if sips -g format "$file" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Parse command line arguments
web_resize=false
frame_color=$DEFAULT_FRAME_COLOR
ratio=$DEFAULT_RATIO
use_file_picker=false
reset_size=false
apply_uniform_padding=false

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
        -f|--files)
            use_file_picker=true
            shift
            ;;
        -p|--preserve_size)
            reset_size=true
            shift
            ;;
        -u|--uniform)
            apply_uniform_padding=true
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 [-w|--web] [-c|--color COLOR] [-r|--ratio RATIO] [-f|--files] [-p|--preserve_size] [-u|--uniform]"
            exit 1
            ;;
    esac
done

if [[ $use_file_picker == true ]]; then
    # Use osascript to choose files and convert to POSIX paths
    # The AppleScript returns paths separated by null characters as delimiters
    selected_files=$(osascript <<EOF | tr '\n' '\0'
        set fileList to choose file with multiple selections allowed with prompt "Choose images to frame:" of type {"public.image"}
        set posixPaths to {}
        repeat with aFile in fileList
            set end of posixPaths to POSIX path of aFile & linefeed
        end repeat
        return posixPaths as string
EOF
    )
    
    if [[ -z "$selected_files" ]]; then
        echo "No files selected"
        exit 0
    fi
    
    # Process each selected file using null character as delimiter
    echo "$selected_files" | tr '\0' '\n' | while IFS= read -r file; do
        # Skip empty lines
        [[ -z "$file" ]] && continue
        
        # Remove possible quotes and trailing spaces
        file=$(echo "$file" | tr -d '"' | sed 's/[[:space:]]*$//')
        
        if [[ -f "$file" ]] && is_image "$file"; then
            echo ""
            if [[ $apply_uniform_padding == true ]]; then
                echo "Processing $file with uniform padding..."
                pad_uniformly "$file" "$frame_color" "$web_resize"
                echo "$file processed with uniform padding."
            else
                echo "Processing $file with ratio padding..."
                pad_to_ratio "$file" "$frame_color" "$ratio" "$web_resize"
                echo "$file processed with padding to $ratio."
            fi
        else
            echo "Skipping $file - not a valid image file"
        fi
    done
else
    # Create framed directory in current directory for local mode
    mkdir -p "./framed"
    
    # Process all image files in current directory (original behavior)
    for file in *.{jpg,JPG,jpeg,JPEG,png,PNG,HEIC,heic}(N); do
        if is_image "$file"; then
            echo ""
            if [[ $apply_uniform_padding == true ]]; then
                echo "Processing $file with uniform padding..."
                pad_uniformly "$file" "$frame_color" "$web_resize"
                echo "$file processed with uniform padding."
            else
                echo "Processing $file with ratio padding..."
                pad_to_ratio "$file" "$frame_color" "$ratio" "$web_resize"
                echo "$file processed with padding to $ratio."
            fi
        else
            echo "Skipping $file - not a valid image file"
        fi
    done
fi
if [[ $use_file_picker == true ]]; then
    # Use osascript to choose files and convert to POSIX paths
    # The AppleScript returns paths separated by null characters as delimiters
    selected_files=$(osascript <<EOF | tr '\n' '\0'
        set fileList to choose file with multiple selections allowed with prompt "Choose images to frame:" of type {"public.image"}
        set posixPaths to {}
        repeat with aFile in fileList
            set end of posixPaths to POSIX path of aFile & linefeed
        end repeat
        return posixPaths as string
EOF
    )
    
    if [[ -z "$selected_files" ]]; then
        echo "No files selected"
        exit 0
    fi
    
    # Process each selected file using null character as delimiter
    echo "$selected_files" | tr '\0' '\n' | while IFS= read -r file; do
        # Skip empty lines
        [[ -z "$file" ]] && continue
        
        # Remove possible quotes and trailing spaces
        file=$(echo "$file" | tr -d '"' | sed 's/[[:space:]]*$//')
        
        if [[ -f "$file" ]] && is_image "$file"; then
            echo ""
            echo "Processing $file..."
            pad_to_ratio "$file" "$frame_color" "$ratio" "$web_resize"
            echo "$file processed with padding to $ratio."
        else
            echo "Skipping $file - not a valid image file"
        fi
    done
else
    # Create framed directory in current directory for local mode
    mkdir -p "./framed"
    
    # Process all image files in current directory (original behavior)
    for file in *.{jpg,JPG,jpeg,JPEG,png,PNG,HEIC,heic}(N); do
        if is_image "$file"; then
            echo ""
            echo "Processing $file..."
            pad_to_ratio "$file" "$frame_color" "$ratio" "$web_resize"
            echo "$file processed with padding to $ratio."
        else
            echo "Skipping $file - not a valid image file"
        fi
    done
fi
