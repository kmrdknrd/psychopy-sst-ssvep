import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy.stats as stats

from make_noise import *
from make_gabor import *
from make_annulus import *
# from make_fixation import *


def single_trial(
    screen_width_px = 2560, screen_height_px = 1440, diagonal_cm = 68.58,
    image_size = 1024, ref_rate_hz = 120, my_dpi = 109, stim_dir = "stimuli",
    snr = 1/3, stop_trial = True,
    only_noise_ms = 500, SSD_ms = 250, trial_length_ms = 2000,
    rotation_deg = 45, gabor_freq_cm = 2.98,
    # noise_static = False, gabor_static = False, annulus_static = False,
    noise_freq_hz = 20, gabor_freq_hz = 24, ann_freq_hz = 30
    ):

    #turn value matrix into .png image
    def plotter(value_matrix, image_name):
        plt.figure(figsize = (image_size/my_dpi, image_size/my_dpi), dpi = my_dpi)
        plt.xticks([])
        plt.yticks([])
        plt.axis('off')
        plt.imshow(value_matrix, vmin = 0, vmax = 1, cmap = 'gray')
        plt.savefig(image_name, dpi = my_dpi, transparent = True)
        plt.close('all')
        plt.clf()
        plt.cla()


    #break snr apart
    noise_ratio = 1 / (snr+1)
    signal_ratio = 1 - noise_ratio


    # #test images
    # noise_test = (make_noise() - 0.25) * 2*noise_ratio + 0.5*signal_ratio
    # plotter(noise_test, "stimuli/noise_test.png")

    # gabor_test = make_gabor() * signal_ratio * 2
    # noise_gabor_test = noise_test + gabor_test
    # plotter(noise_gabor_test, "stimuli/noise_gabor_test.png")

    # if stop_trial:
    #     annulus_test = make_annulus() * signal_ratio * 2
    #     noise_gabor_annulus_test = noise_gabor_test + annulus_test
    #     plotter(noise_gabor_annulus_test, "stimuli/noise_gabor_annulus_test.png")


    #turn component frequencies into frame lengths
    component_lengths = ref_rate_hz / np.array([noise_freq_hz, gabor_freq_hz, ann_freq_hz])
    print(
        """
        Length in frames:
            Noise - {0}
            Gabor - {1}
            Annulus - {2}
        """.format(*component_lengths)
        )

    if(np.any(component_lengths % 1 != 0)):
        raise ValueError(
            """
            Frame lengths must be integers.
            Your component frequencies don't divide your refresh rate.
            """
            )

    noise_frame_length, gabor_frame_length, ann_frame_length = tuple([int(comp) for comp in component_lengths])

    #calculate how many frames noise / + gabor / + annulus
    noise_frames = int(only_noise_ms/1000 * ref_rate_hz)
    if stop_trial:
        gabor_frames = int(SSD_ms/1000 * ref_rate_hz)
        ann_frames = int(trial_length_ms/1000 * ref_rate_hz) - gabor_frames
    else:
        gabor_frames = int(trial_length_ms/1000 * ref_rate_hz)
        ann_frames = 0


    #generate images for single trial
    #counters
    noise_counter, gabor_counter, ann_counter, image_counter = 0, 0, 0, 0
    gabor_on, ann_on = 0, 0
    frame_lengths_arr = np.empty(1)
    frame_length = 0

    #only noise
    for i in range(noise_frames):
        if noise_counter == 0:
            noise_values = (make_noise(screen_width_px = screen_width_px,
                                       screen_height_px = screen_height_px,
                                       diagonal_cm = diagonal_cm) - 0.25) * 2*noise_ratio + 0.5*signal_ratio
            new_image = True

        if new_image:
            filename = stim_dir + "/trial_image_" + str(image_counter) + ".png"
            plotter(noise_values, filename)

            image_counter += 1
            frame_lengths_arr = np.append(frame_lengths_arr, frame_length)
            frame_length = 1
            new_image = False

        else:
            frame_length += 1

        noise_counter += 1

        if noise_counter == noise_frame_length: noise_counter = 0 

    #add gabor
    gabor_values = make_gabor(rotation_deg = rotation_deg,
                              gabor_freq_cm = gabor_freq_cm,
                              screen_width_px = screen_width_px,
                              screen_height_px = screen_height_px,
                              diagonal_cm = diagonal_cm) * signal_ratio * 2
    for i in range(gabor_frames):
        if noise_counter == 0:
            noise_values = (make_noise(screen_width_px = screen_width_px,
                                       screen_height_px = screen_height_px,
                                       diagonal_cm = diagonal_cm) - 0.25) * 2*noise_ratio + 0.5*signal_ratio
            new_image = True

        if gabor_counter == 0:
            gabor_on = -gabor_on + 1
            new_image = True

        if new_image:
            filename = stim_dir + "/trial_image_" + str(image_counter) + ".png"
            plotter(noise_values + gabor_values*gabor_on, filename)

            image_counter += 1
            frame_lengths_arr = np.append(frame_lengths_arr, frame_length)
            frame_length = 1
            new_image = False

        else:
            frame_length += 1

        noise_counter += 1
        gabor_counter += 1

        if noise_counter == noise_frame_length: noise_counter = 0 
        if gabor_counter == gabor_frame_length: gabor_counter = 0 

    #add annulus
    ann_values = make_annulus(screen_width_px = screen_width_px,
                              screen_height_px = screen_height_px,
                              diagonal_cm = diagonal_cm) * signal_ratio * 2
    for i in range(ann_frames):
        if noise_counter == 0:
            noise_values = (make_noise(screen_width_px = screen_width_px,
                                       screen_height_px = screen_height_px,
                                       diagonal_cm = diagonal_cm) - 0.25) * 2*noise_ratio + 0.5*signal_ratio
            new_image = True

        if gabor_counter == 0:
            gabor_on = -gabor_on + 1
            new_image = True

        if ann_counter == 0:
            ann_on = -ann_on + 1
            new_image = True

        if new_image:
            filename = stim_dir + "/trial_image_" + str(image_counter) + ".png"
            plotter(noise_values + gabor_values*gabor_on + ann_values*ann_on, filename)

            image_counter += 1
            frame_lengths_arr = np.append(frame_lengths_arr, frame_length)
            frame_length = 1
            new_image = False
            
        else:
            frame_length += 1

        noise_counter += 1
        gabor_counter += 1
        ann_counter += 1

        if noise_counter == noise_frame_length: noise_counter = 0 
        if gabor_counter == gabor_frame_length: gabor_counter = 0 
        if ann_counter == ann_frame_length: ann_counter = 0 

    frame_lengths_arr = np.append(frame_lengths_arr, frame_length)[2:]
    frame_lengths_arr = [int(i) for i in frame_lengths_arr]

    return frame_lengths_arr, noise_frames, gabor_frames, ann_frames



def exceler(frame_lengths, file_path):

    image_names = ["stimuli/trial_image_" + str(i) + ".png" for i in range(len(frame_lengths))]
    df = pd.DataFrame({'stim_name': image_names, 'n_frames': frame_lengths})
    df.to_excel(file_path, index = False)


