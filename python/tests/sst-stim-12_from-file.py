import numpy as np
import time

from psychopy import visual, event
from pathlib import Path

# create a window
win = visual.Window(size = [1920, 1080], units="pix")

# get files that end with .png
# test_path = Path("/Users/konradmikalauskas/Library/CloudStorage/OneDrive-UvA/stop-signal-psychopy/tests")
test_path = Path(__file__).parent
file_list = [file for file in test_path.iterdir() if file.suffix == '.png']

# order images in increasing numeric order
right_order = np.empty(len(file_list))
unordered_file_numbers = [int(str(file).split('_')[-1][:-4]) for file in file_list] # get numbers at end of filenames
for count, file_idx in enumerate(unordered_file_numbers):
    right_order[file_idx] = count # create order to sort file_list by
file_list = [file_list[int(i)] for i in right_order] # correctly ordered

# flicker frequency
stim_flicker_freq = 12  # in Hz
frame_rate = 120  # refresh rate in Hz
stim_frames_per_cycle = int(frame_rate / stim_flicker_freq)

# load images
stim_img = []
for file in file_list:
    img = visual.ImageStim(
        win = win,
        image = file,
        colorSpace = 'rgb1',
        units = 'pix')
    stim_img.append(img)

# flicker loop
while True:
    for file in stim_img:
        for frameN in range(stim_frames_per_cycle):
            file.draw()
            win.flip()
    
    # check for quit:
    if event.getKeys(keyList=["space"]):
        break

win.close()


