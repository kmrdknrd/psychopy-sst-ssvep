import numpy as np
import matplotlib.pyplot as plt
import time

from psychopy import visual, event
from pathlib import Path

from make_noise import *
from make_gabor import *
from make_annulus import *

### hard-coded, change as needed ###
# window
win = visual.Window(size = [1920, 1080], units="pix")

# flicker frequency
noise_flicker_f = 12  # in Hz
go_sig_flicker_f = 20  # in Hz
stop_sig_flicker_f = 30  # in Hz
frame_rate = 120  # refresh rate in Hz

# snr
snr = 1/2.5
noise_ratio = 1 / (snr+1)
signal_ratio = 1 - noise_ratio
### end hard-coded ###


# frames per cycle (fpc)
noise_fpc = int(frame_rate / noise_flicker_f)
go_sig_fpc = int(frame_rate / (2 * go_sig_flicker_f))
stop_sig_fpc = int(frame_rate / (2 * stop_sig_flicker_f))

## create image values for trial
# 60x different noise img values
noise_values = []
for i in range(13):
    noise_values.append((make_noise() - 0.25) * 2*noise_ratio + 0.5*signal_ratio)

# 1x gabor img values
gabor_values = make_gabor() * signal_ratio * 2

# 1x annulus img values
annulus_values = make_annulus() * signal_ratio * 2

# 1x alpha layer
alpha_layer = np.where(np.isnan(noise_values[0]), 0, 1)

print("Images values created")


# test_path = Path("/Users/konradmikalauskas/Library/CloudStorage/OneDrive-UvA/stop-signal-psychopy/tests/test_images_jul24/")
test_path = Path(__file__).parent / "test_images"
test_path.mkdir(exist_ok=True)

## create images for test trial
for frameN in range(frame_rate):
    img = noise_values[frameN // noise_fpc].copy()

    # add gabor at 20 Hz
    if (frameN // go_sig_fpc) % 2 == 0:
        img += gabor_values
    # add annulus at 30 Hz
    if (frameN // stop_sig_fpc) % 2 == 0:
        img += annulus_values
    
    # add alpha layer
    img = np.dstack((img, img, img, alpha_layer))

    # save image
    plt.imsave(test_path / f"test_image_{frameN}.png", img)

print("Images saved")


# get image filenames in correct order
file_list = [file for file in test_path.iterdir() if file.suffix == '.png']
right_order = np.empty(len(file_list))
unordered_file_numbers = [int(str(file).split('_')[-1][:-4]) for file in file_list] # get numbers at end of filenames
for count, file_idx in enumerate(unordered_file_numbers):
    right_order[file_idx] = count # create order to sort file_list by
file_list = [file_list[int(i)] for i in right_order] # correctly ordered

# load images
stim_img = []
for file in file_list:
    img = visual.ImageStim(
        win = win,
        image = file,
        colorSpace = 'rgb1',
        pos = (0, 0),
        size = (1000, 1000),
        units = 'pix')
    stim_img.append(img)

print("Images loaded, starting test")

# show images
while True:
    for frameN in range(frame_rate):
        # Draw stim
        stim_img[frameN].draw()
        win.flip()

    # check for quit:
    if event.getKeys(keyList=["space"]):
        break

# insight: for acutal experiment, make three loops: noise, +go, +stop; less images to make bcuz you can keep recycling