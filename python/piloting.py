# Created on 05/12/22 at 3:03 PM

# Author: Konrad Mikalauskas

from psychopy import core, visual, sound, event, logging, parallel
from psychopy import gui

import os
import time

import numpy as np
import pandas as pd
import numpy as np

from PIL import Image
from scipy.io import savemat
# from natsort import natsorted

# COM1 - 03F8-03FF, 0x...4

# EEG port
global pp_address
global trigger_data
pp_address = 0x4050
port = parallel.ParallelPort(address = pp_address)

def vsync():
    port.setData(trigger_data)
    return


# window color
bg_rgb = 90
bg_scale = [-1 + 2 * (bg_rgb/255)] *3

# set up experiment window
window = visual.Window(units = "pix",
                       allowGUI = True,
                       size = (2560, 1440),
                       color = bg_scale,
                       screen = 1,
                       fullscr = False)
window.recordFrameIntervals = False

refresh_r = round(window.getActualFrameRate())
print('refresh rate: %s Hz' % refresh_r)
#abortKey = 'Q'

## SINGLE BLOCK
# get images
pregen_dir = '/Users/konradmikalauskas/Desktop/psychopy2022/exp/stimuli/'
n_trials = len(os.listdir(pregen_dir))
times_trials = np.zeros((n_trials, 200))

for trial in range(1, n_trials+1):
    print("loading trial {0} images".format(trial))
    trial_folder = pregen_dir + 'trial_' + str(trial)
    #
    ## get file list
    file_list = os.listdir(trial_folder) # get file names in image directory
    file_list = [file for file in file_list if file.startswith('trial_image')] # exclude xlsx sheet with frame lengths
    # file_list = natsorted(file_list)
    #
    ## order images in increasing numeric order
    unordered_file_numbers = [int(file.split('_')[-1][:-4]) for file in file_list] # get numbers at end of filenames
    right_order = np.empty(len(unordered_file_numbers))
    for count, file_idx in enumerate(unordered_file_numbers):
        right_order[file_idx] = count # create order to sort file_list by
    file_list = [file_list[int(i)] for i in right_order] # correctly ordered
    #
    ## get all frame values
    frames_dir = trial_folder + "/trial.xlsx"
    frames = pd.read_excel(frames_dir)
    frames = frames['n_frames']
    frames_total = sum(frames)
    #
    ## get event frame values
    event_frames_dir = trial_folder + "/event_frames.xlsx"
    event_frames = pd.read_excel(event_frames_dir).squeeze().to_numpy()
    #
    ## get image paths
    stim_img = []
    stim_name = []
    for i in range(len(file_list)):
        stim_name.append(trial_folder +'/' + file_list[i])  # file name
        img = Image.open(stim_name[i])
        stim_img.append(visual.ImageStim(win=window, image = img, pos = (0, 0)))  # png image handle
    print("loaded trial {0} images".format(trial))
    #
    ## timing and ports
    times = []
    timer = core.Clock()
    frames_since_event = 0
    #
    ## run trial
    port.setData(0)
    port.setData(1)
    event = 0
    print("running trial {0}".format(trial))
    for img in range(len(stim_img)):
        stim_img[img].draw()
        for frame in range(frames[img]):
            frames_since_event += 1
            if np.any(frames_since_event == event_frames[event]):
                event += 1
                trigger_data = 2**event
                window.callOnFlip(vsync)
                frames_since_event = 0
            times.append(timer.getTime())
            window.flip()
    window.flip()
    port.setData(0)
    print("trial {0} end, sleeping for 1s".format(trial))
    time.sleep(1)

times = np.array(times)

# # Add EEG trigger to target presentation
# window.callOnFlip(vsync)
# triggerData = 1
# window.flip()

# time.sleep(0.01)
# triggerData = 0
# port.setData(0) 

# while True:
#     keys = event.getKeys(keyList = ['space','escape', None])
#     port.setData(2)

#     if 'space' in keys:
#         time.sleep(0.01)
#         triggerData = 0
#         port.setData(0)
#     elif 'escape' in keys:
#         core.quit()
#         break

