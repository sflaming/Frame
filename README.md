# Frame
Frame an image with extra padding set to your preferred ratio and colour.

## How to use it
Place the script in any folder in your `$PATH`, then call it from any folder with images. It will process all .jpg/.jpeg files in the folder from which it is called and place them in a new folder `./framed`. The padding defaults to white `ffffff` and `5:4`.

### Detailed instructions
0. **Install Dependencies**: Ensure you have `sips` and `zsh` installed (standard on macOS).

1. **Place the Script in the Right Directory**: 
   Download the script or clone the repository, then move your script into a folder that's already in your `PATH`, like `/usr/local/bin` or a custom directory like `~/bin` if you have that in your `PATH`.

2. **Make the Script Executable**:
   Run this command to make the script executable:
   ```shell
   chmod +x ~/bin/your_script_name
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

- Basic usage: `./frame.sh`
- Web resize only: `./frame.sh -w`
- Custom colour only: `./frame.sh -c FFFFFF`
- Custom ratio only: `./frame.sh -r 5:4`
- Mix and match any flags: `./frame.sh -w -c FFFFFF -r 5:4`


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


## v1.1
Parameters are now flag-based and can be specified independently and in any order:

- `-w`, `--web`: Enable web-optimized resizing (1080px wide for landscape, max 1350px tall for portrait)
- `-c`, `--colour`: Set frame colour using hex values (e.g., FFFFFF for white)
- `-r,` `--ratio`: Set aspect ratio (e.g., 5:4, 16:9, 1:1)
- `-f` `--files`: Choose files from a file selector
TODO - ``: Disable metadata extraction

Usage examples:

- Basic usage: `./frame.sh`
- Web resize only: `./frame.sh -w`
- Custom colour only: `./frame.sh -c FFFFFF`
- Custom ratio only: `./frame.sh -r 5:4`
- Mix and match any flags: `./frame.sh -w -c FFFFFF -r 5:4`

All parameters are optional and will use defaults if not specified (colour: FFFFFF, ratio: 5:4).

TODO #1 Width not always as expected -- should be 1080 wide 
TODO extract original image's ppi/dpi for later use
TODO create function to resize an image file (set dpi and dimensions using sips) 
TODO use custom resize function in UI for user customization
TODO use custom resize function to resize image output to original image's dpi, 
TODO customize font with relative values (default, smaller, smallest, larger, largest)
<<<<<<< HEAD
TODO flag to set specific metadata usage (default to all, but when this flag is activate show a ui with checkboxes for camera, lens, focal length, ISO, etc)

TODO resize framed image to the original dimensions
TODO stack two images in a diptych. the gap between them should be the same as the gap to the edge of a normal framed image (half the new width added by the min multiplyer) 
=======
TODO flag to set specific metadata usage (default to all, but when this flag is activate show a ui with checkboxes for camera, lens, focal length, ISO, etc)
>>>>>>> 60c3fcf (file picker added)
