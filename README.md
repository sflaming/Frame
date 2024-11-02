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

Or use any colour and ratio combination. Colour required to set a ratio.

## Example Usage
```
./add_border.zsh [FRAME_COLOR] [ASPECT_RATIO]
```
- FRAME_COLOR: Optional. Specify the frame color in HEX (e.g., `FFFFFF` for white).
- ASPECT_RATIO: Optional. Set the desired aspect ratio (e.g., `5:4`).


```
frame.sh edd3ad
```
![testImage_5-4_padded_edd3ad](https://github.com/user-attachments/assets/553ef914-0e1c-4cf0-ae25-de76ba85a336)

```
frame.sh edd3ad 16:9
```
![testImage_16-9_padded_edd3ad](https://github.com/user-attachments/assets/2eeeb352-72b4-4e6e-a2ef-bcb612639e9c)

## Contribution
I welcome your feedback and contributions! If you encounter any issues or have ideas for enhancements, feel free to open an issue or submit a pull request.

Test image from V1SteakSauce on [reddit](https://www.reddit.com/r/VIDEOENGINEERING/comments/zghdo1/i_made_my_perfect_1080p_test_image_today_thought/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
