# Created on 05/12/22 at 3:03 PM
# Author: Konrad Mikalauskas

# Import libraries
import os
import time
import numpy as np
import pandas as pd
from PIL import Image
from psychopy import core, visual, event, parallel

# VSync function
def vsync():
    port_write.setData(trigger_data)
    return

# Function to draw and flip (i.e., show) stimulus
def draw_n_flip(stim, window, sleep_s = 0):
    stim.draw()
    window.flip()
    time.sleep(sleep_s)
    return

## Set-up EEG ports
global pp_write_address
global trigger_data

# Write address
pp_write_address = 0x4050
port_write = parallel.ParallelPort(address = pp_write_address)

# Read address
pp_read_address = 0x4051
port_read = parallel.ParallelPort(address = pp_read_address) # statusDefault is 125


## Set-up experiment window
# Background color
bg_scale = [-1 + 2 * (90/255)] * 3

# Create window
window = visual.Window(units = "pix",
                       allowGUI = False,
                       size = (2560, 1440),
                       color = bg_scale,
                       screen = 0,
                       fullscr = False)

# Don't record frame intervals
window.recordFrameIntervals = False

# Get refresh rate
refresh_r = round(window.getActualFrameRate())
print(f"refresh rate: {refresh_r} Hz")


## Experiment instructions
# Create blank image
blank = visual.ImageStim(win = window, image = None)

def instruction_screen(window = window, examples_dir = "example_images"):
    # Instruction text
    instr_text = visual.TextStim(window,
                                 text = "THICK = LEFT,\nTHIN = RIGHT,\nCIRCLE = STOP",
                                 color = (1,1,1),
                                 height = 50)

    # Thick text and example image
    thick_text = visual.TextStim(window,
                                 text = "THICK",
                                 color = (1,1,1),
                                 height = 50)
    thick = Image.open(examples_dir + '/thick.png')
    thick_img = visual.ImageStim(win = window,
                                 image = thick)
    
    # Thin text and example image
    thin_text = visual.TextStim(window,
                                text = "THIN",
                                color = (1,1,1),
                                height = 50)
    thin = Image.open(examples_dir + '/thin.png')
    thin_img = visual.ImageStim(win = window,
                                image = thin)

    # Circle text and example image
    circ_text = visual.TextStim(window,
                                text = "CIRCLE",
                                color = (1,1,1),
                                height = 50)

    circ = Image.open(examples_dir + '/circle.png')
    circ_img = visual.ImageStim(win = window,
                                image = circ)

    # draw space text
    space_text = visual.TextStim(window,
                                text = "Press 'space' to begin:)",
                                color = (1,1,1),
                                height = 50)
    
    # Draw and flip
    draw_n_flip(instr_text, window, 5)

    draw_n_flip(thick_text, window, 1)
    draw_n_flip(thick_img, window, 2)
    draw_n_flip(blank, window, 0.5)

    draw_n_flip(thin_text, window, 1)
    draw_n_flip(thin_img, window, 2)
    draw_n_flip(blank, window, 0.5)
    
    draw_n_flip(circ_text, window, 1)
    draw_n_flip(circ_img, window, 2)
    draw_n_flip(blank, window, 0.5)

    draw_n_flip(space_text, window)

    # Wait for spacebar press
    keys = event.waitKeys(keyList=['space'])

    draw_n_flip(blank, window)

# display instruction screen
instruction_screen()

# get images
pregen_dir = '/Users/konradmikalauskas/Desktop/psychopy2022/exp/stimuli/'
# pregen_dir = 'D:/Users/Michael/stimuli_12-20-30_1056x1056_npy&png/'
n_blocks = len([dir for dirs in os.listdir(pregen_dir) if dirs.startswith('block')])

port_write.setData(0)

img_for_alpha = np.load('stimuli/block_1/trial_1/trial_image_0.npy')
alpha_layer = np.where(img_for_alpha == 0, 0, 255)

for block in range(1, n_blocks+1):
    block_dir = pregen_dir + 'block_' + str(block) + '/'
    # get number of trials by counting number of directories in block_dir
    n_trials = len([dir for dir in os.listdir(block_dir) if dir.startswith('trial')])
    print(f"block {block}")

    block_text = visual.TextStim(window, text = "BLOCK{0}".format(block), color = (1,1,1), height = 100)
    block_text.draw()
    window.flip()
    time.sleep(1)

    blank.draw()
    window.flip()
    time.sleep(1)

    for trial in range(1, n_trials+1):
        print("loading trial {0} images".format(trial))
        trial_folder = block_dir + 'trial_' + str(trial)
        
        # get files that end with .npy
        file_list = os.listdir(trial_folder)
        file_list = [file for file in file_list if file.endswith('.npy')]

        
        # order images in increasing numeric order
        right_order = np.empty(len(file_list))
        unordered_file_numbers = [int(file.split('_')[-1][:-4]) for file in file_list] # get numbers at end of filenames
        for count, file_idx in enumerate(unordered_file_numbers):
            right_order[file_idx] = count # create order to sort file_list by
        file_list = [file_list[int(i)] for i in right_order] # correctly ordered
        
        # get all frame values
        frames_dir = trial_folder + "/trial.xlsx"
        frames = pd.read_excel(frames_dir)
        frames = frames['n_frames']
        frames_total = sum(frames)
        
        # get event frame values
        event_frames_dir = trial_folder + "/event_frames.xlsx"
        event_frames = pd.read_excel(event_frames_dir).squeeze().to_numpy()

        # get stop/go and thick/thin
        parameters_file = trial_folder + "/parameters.xlsx"
        pars = pd.read_excel(parameters_file).squeeze().to_numpy()
        thick_thin = int(pars[2])
        go_stop = bool(pars[0])
        if thick_thin == 0:
            thick_thin = 32
        else:
            thick_thin = 64


        # get image paths
        stim_img = []
        stim_name = []
        for file in range(len(file_list)):
            stim_name.append(trial_folder +'/' + file_list[file])
            img = np.load(stim_name[file])
            rgba_image = np.dstack((img, img, img, alpha_layer))
            stim_img.append(visual.ImageStim(
                win = window,
                image = rgba_image / 255.0,
                size = np.shape(img),
                colorSpace = 'rgb1',
                units = 'pix'
                )
            )
        print("loaded trial {0} images".format(trial))
        
        ## timing and ports
        times = []
        timer = core.Clock()
        frames_since_event = 0
        
        ## run trial
        # send thick or thin to actiview
        port_write.setData(thick_thin)
        time.sleep(0.01)
        port_write.setData(0)
        port_write.setData(1)
        trigger = 0

        print("running trial {0}".format(trial))
        
        # image loop
        for img in range(len(stim_img)):
            # draw img-th image
            stim_img[img].draw()
            
            # frame loop
            for frame in range(frames[img]):
                # count each frame
                frames_since_event += 1
                
                # log key presses
                #keys = port_read.readData()
                # if keys == 109 or keys == 253:
                #     print(keys)
                #     break # exit frame loop
                
                if np.any(frames_since_event == event_frames[trigger]):
                    # send event trigger to ActiView
                    trigger += 1
                    trigger_data = 2**trigger
                    window.callOnFlip(vsync)
                    
                    # restart frame counter
                    frames_since_event = 0
                
                # log timing of each image presentation
                times.append(timer.getTime())
                
                # presents current image for one frame
                window.flip()
                
            # if keys == 109 or keys == 253:
            #     print(keys)
            #     blank.draw()
            #     window.flip()
            #     break # exit image loop
        
        blank.draw()
        window.flip()
        port_write.setData(0)
        print("trial end")

    block_end_text = visual.TextStim(window, text = "BLOCK{0} end. Good work! Press 'space' to continue to next block", color = (1,1,1), height = 30)
    block_end_text.draw()
    window.flip()

    keys = event.waitKeys(keyList=['space'])

    blank.draw()
    window.flip()
    time.sleep(1)

