# Frame

Frame an image with extra padding set to your preferred ratio and colour.

## How to use it
Install the project script as `~/bin/frame`, then call `frame` from any folder
with images. It processes supported images in the current directory and writes
JPEGs to `./framed`. You can also give it image paths directly. The default
frame is white (`FFFFFF`) at a `5:4` ratio.

### Detailed instructions
0. **Install Dependencies**: Ensure you have `sips` and `zsh` installed (standard on macOS).

1. **Place the Script in the Right Directory**: 
   Download the script or clone the repository, then move your script into a folder that's already in your `PATH`, like `/usr/local/bin` or a custom directory like `~/bin` if you have that in your `PATH`.

2. **Install the command**:

   Run this from the cloned project directory:
   ```shell
   chmod +x frame.sh
   ln -sf "$PWD/frame.sh" ~/bin/frame
   ```

3. **Add Custom Folder to PATH (if necessary)**:
   If you're using a custom folder (like `~/bin`) that isn't already in your `PATH`, add it by editing your `~/.zshrc` file:
   ```shell
   echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
   ```
   Then, reload the configuration:
   ```shell
   source ~/.zshrc
   ```

After these steps, you can call your script from any folder by typing its name in the terminal.

Or use any colour and ratio combination.

## Usage examples:

- Basic usage: `frame`
- A particular image: `frame ~/Pictures/photo.jpg`
- Web resize only: `frame -w`
- Custom colour only: `frame -c EDD3AD`
- Custom ratio only: `frame -r 16:9`
- Mix and match: `frame -w -c EDD3AD -r 16:9`
- Preserve the original image's longest dimension: `frame -p`
- Add an even border rather than fitting a ratio: `frame -u`
- Choose files in the macOS picker: `frame -f`


```
frame.sh -c edd3ad
```
![testImage_5-4_padded_edd3ad](https://github.com/user-attachments/assets/553ef914-0e1c-4cf0-ae25-de76ba85a336)

```
frame.sh -c edd3ad -r 16:9
```
![testImage_16-9_padded_edd3ad](https://github.com/user-attachments/assets/2eeeb352-72b4-4e6e-a2ef-bcb612639e9c)

## Contribute
Feedback and contributions welcome! If you encounter any issues or have ideas for enhancements, open an issue or submit a pull request.

Test image from V1SteakSauce on [reddit](https://www.reddit.com/r/VIDEOENGINEERING/comments/zghdo1/i_made_my_perfect_1080p_test_image_today_thought/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)

# Changelog
Latest:
extract metadata and use it in captions
have up to three lines of text, with two that are customizable, and another populated with shutterspeed, ISO, focal length, and  metadata 


## Options

- `-w`, `--web`: web-optimized resizing (1080px for landscape, 1350px for portrait)
- `-c`, `--color` (or `--colour`): six-digit hex frame colour
- `-r`, `--ratio`: frame ratio such as `5:4`, `16:9`, or `1:1`
- `-f`, `--files`: choose images with the macOS picker
- `-p`, `--preserve-size`: scale the resulting image back to the source's longest edge
- `-u`, `--uniform`: add an even border rather than a ratio frame

TODO flag to set specific metadata usage (default to all, but when this flag is activate show a ui with checkboxes for camera, lens, focal length, ISO, etc)
TODO resize framed image to the original dimensions
TODO stack two images in a diptych. the gap between them should be the same as the gap to the edge of a normal framed image (half the new width added by the min multiplyer) 
