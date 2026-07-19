#!/usr/bin/env zsh

# Frame an image with a coloured border while preserving the full image.

emulate -L zsh
setopt extended_glob null_glob

DEFAULT_FRAME_COLOR="FFFFFF"
DEFAULT_RATIO="5:4"
MIN_MULTIPLIER="1.07"

usage() {
  cat <<'EOF'
Usage: frame [options] [image ...]

Add a frame around images. With no image arguments, frames supported images in
the current directory and writes them to ./framed. Output is always JPEG.

Options:
  -c, --color HEX        Frame colour (default: FFFFFF)
  -r, --ratio WIDTH:HEIGHT
                          Frame ratio (default: 5:4). Portraits use it rotated.
  -w, --web              Resize output for the web (1080px landscape / 1350px portrait)
  -p, --preserve-size    Resize the final frame so its longest edge matches the source
  -u, --uniform          Add an even border instead of fitting a target ratio
  -f, --files            Select images in the macOS file picker
  -h, --help             Show this help
EOF
}

fail() {
  print -u2 -- "frame: $*"
  exit 1
}

is_image() {
  sips -g format "$1" >/dev/null 2>&1
}

image_dimension() {
  local property=$1
  local image_path=$2
  sips -g "$property" "$image_path" 2>/dev/null | awk 'END { print $2 }'
}

web_resize_output() {
  local output_path=$1
  local width height max_dimension
  width=$(image_dimension pixelWidth "$output_path") || return 1
  height=$(image_dimension pixelHeight "$output_path") || return 1

  if (( width > height )); then
    max_dimension=1080
  else
    max_dimension=1350
  fi

  sips -Z "$max_dimension" -s format jpeg -s formatOptions 100 "$output_path" --out "$output_path" >/dev/null 2>&1
}

print_success() {
  local image_path=$1 output_path=$2 style=$3 frame_color=$4
  local width height
  width=$(image_dimension pixelWidth "$output_path") || return 1
  height=$(image_dimension pixelHeight "$output_path") || return 1

  print -- "✓ Framed ${image_path:t} → ${output_path:h:t}/${output_path:t} (${width}×${height} px, ${style}, #${frame_color})"
}

output_path_for() {
  local image_path=$1 frame_color=$2 suffix=$3
  local image_dir=${image_path:h}
  local output_dir="$image_dir/framed"
  local base_name=${image_path:t:r}
  local color_suffix=""

  [[ "$frame_color" == "$DEFAULT_FRAME_COLOR" ]] || color_suffix="_${frame_color:l}"
  mkdir -p "$output_dir" || return 1
  print -r -- "$output_dir/${base_name}_${suffix}${color_suffix}.jpg"
}

frame_to_ratio() {
  local image_path=$1 frame_color=$2 ratio=$3 web_resize=$4 preserve_size=$5
  local ratio_x=${ratio%%:*} ratio_y=${ratio##*:}
  local original_width original_height target_ratio base_width base_height final_width final_height original_max output_path

  original_width=$(image_dimension pixelWidth "$image_path") || fail "could not read dimensions for $image_path"
  original_height=$(image_dimension pixelHeight "$image_path") || fail "could not read dimensions for $image_path"

  if (( original_width >= original_height )); then
    target_ratio=$(awk -v x="$ratio_x" -v y="$ratio_y" 'BEGIN { printf "%.12f", x / y }')
  else
    target_ratio=$(awk -v x="$ratio_x" -v y="$ratio_y" 'BEGIN { printf "%.12f", y / x }')
  fi

  base_width=$(awk -v n="$original_width" -v m="$MIN_MULTIPLIER" 'BEGIN { printf "%d", n * m + 0.5 }')
  base_height=$(awk -v n="$original_height" -v m="$MIN_MULTIPLIER" 'BEGIN { printf "%d", n * m + 0.5 }')
  final_width=$(awk -v w="$base_width" -v h="$base_height" -v r="$target_ratio" 'BEGIN { candidate = h * r; printf "%d", (w > candidate ? w : candidate) + 0.5 }')
  final_height=$(awk -v w="$final_width" -v r="$target_ratio" 'BEGIN { printf "%d", w / r + 0.5 }')
  original_max=$(( original_width > original_height ? original_width : original_height ))
  output_path=$(output_path_for "$image_path" "$frame_color" "${ratio_x}-${ratio_y}_padded") || fail "could not create output directory"

  sips -p "$final_height" "$final_width" --padColor "$frame_color" -s format jpeg "$image_path" --out "$output_path" >/dev/null 2>&1 || fail "could not frame $image_path"

  if [[ "$preserve_size" == true ]]; then
    sips -Z "$original_max" "$output_path" --out "$output_path" >/dev/null 2>&1 || fail "could not resize $output_path"
  fi
  if [[ "$web_resize" == true ]]; then
    web_resize_output "$output_path" || fail "could not resize $output_path"
  fi
  print_success "$image_path" "$output_path" "${ratio_x}:${ratio_y} ratio" "$frame_color" || fail "could not read $output_path"
}

frame_uniformly() {
  local image_path=$1 frame_color=$2 web_resize=$3 preserve_size=$4
  local original_width original_height shorter_side padding final_width final_height original_max output_path

  original_width=$(image_dimension pixelWidth "$image_path") || fail "could not read dimensions for $image_path"
  original_height=$(image_dimension pixelHeight "$image_path") || fail "could not read dimensions for $image_path"
  shorter_side=$(( original_width < original_height ? original_width : original_height ))
  padding=$(awk -v side="$shorter_side" -v m="$MIN_MULTIPLIER" 'BEGIN { printf "%d", side * (m - 1) / 2 + 0.5 }')
  final_width=$(( original_width + 2 * padding ))
  final_height=$(( original_height + 2 * padding ))
  original_max=$(( original_width > original_height ? original_width : original_height ))
  output_path=$(output_path_for "$image_path" "$frame_color" "uniform_padded") || fail "could not create output directory"

  sips -p "$final_height" "$final_width" --padColor "$frame_color" -s format jpeg "$image_path" --out "$output_path" >/dev/null 2>&1 || fail "could not frame $image_path"

  if [[ "$preserve_size" == true ]]; then
    sips -Z "$original_max" "$output_path" --out "$output_path" >/dev/null 2>&1 || fail "could not resize $output_path"
  fi
  if [[ "$web_resize" == true ]]; then
    web_resize_output "$output_path" || fail "could not resize $output_path"
  fi
  print_success "$image_path" "$output_path" "uniform border" "$frame_color" || fail "could not read $output_path"
}

web_resize=false
frame_color=$DEFAULT_FRAME_COLOR
ratio=$DEFAULT_RATIO
use_file_picker=false
preserve_size=false
uniform_padding=false
typeset -a image_paths

while (( $# )); do
  case "$1" in
    -w|--web) web_resize=true ;;
    -c|--color|--colour)
      (( $# >= 2 )) || fail "$1 requires a colour"
      frame_color=${2:u}
      shift
      ;;
    -r|--ratio)
      (( $# >= 2 )) || fail "$1 requires a ratio"
      ratio=$2
      shift
      ;;
    -f|--files) use_file_picker=true ;;
    -p|--preserve-size|--preserve_size) preserve_size=true ;;
    -u|--uniform) uniform_padding=true ;;
    -h|--help) usage; exit 0 ;;
    --) shift; image_paths+=("$@"); break ;;
    -*) fail "unknown option: $1" ;;
    *) image_paths+=("$1") ;;
  esac
  shift
done

[[ "$frame_color" =~ '^[0-9A-F]{6}$' ]] || fail "colour must be a six-digit hex value, e.g. EDD3AD"
[[ "$ratio" =~ '^([1-9][0-9]*):([1-9][0-9]*)$' ]] || fail "ratio must use positive whole numbers, e.g. 5:4"
[[ "$use_file_picker" == true && ${#image_paths} -gt 0 ]] && fail "use either --files or image paths, not both"

if [[ "$use_file_picker" == true ]]; then
  image_paths=("${(@f)$(osascript <<'EOF'
set selectedFiles to choose file with multiple selections allowed with prompt "Choose images to frame:" of type {"public.image"}
set AppleScript's text item delimiters to linefeed
return POSIX path of every item of selectedFiles
EOF
)}")
elif (( ${#image_paths} == 0 )); then
  image_paths=( *.(jpg|jpeg|png|heic|tif|tiff|webp)(N) )
fi

(( ${#image_paths} )) || fail "no images found"

for image_path in "${image_paths[@]}"; do
  [[ -f "$image_path" ]] || { print -u2 -- "frame: skipping missing file: $image_path"; continue; }
  is_image "$image_path" || { print -u2 -- "frame: skipping unsupported image: $image_path"; continue; }

  if [[ "$uniform_padding" == true ]]; then
    frame_uniformly "$image_path" "$frame_color" "$web_resize" "$preserve_size"
  else
    frame_to_ratio "$image_path" "$frame_color" "$ratio" "$web_resize" "$preserve_size"
  fi
done
