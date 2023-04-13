import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy.stats as stats
import os

from single_trial import *


def multi_trial(
    n_trials = 5, stop_trial_prop = 1/4,
    # snr_mean = 1/3, snr_sd = 1/15,
    only_noise_ms_mean = 500, only_noise_ms_sd = 50,
    SSD_ms_mean = 250, SSD_ms_sd = 25,
    stim_dir = "stimuli"
    ):

    # go- or stop-trials
    stop_trials = stats.bernoulli.rvs(stop_trial_prop, 0, n_trials)
    stop_trials = [bool(i) for i in stop_trials]

    # # SNRs
    # snr_vec = stats.norm.rvs(snr_mean, snr_sd, n_trials)

    # durations of each component
    only_noise_ms_vec = stats.norm.rvs(only_noise_ms_mean, only_noise_ms_sd, n_trials)
    SSD_ms_vec = stats.norm.rvs(SSD_ms_mean, SSD_ms_sd, n_trials)

    # gabor parameters
    rotation_deg_vec = stats.uniform.rvs(0, 180, n_trials) # rotation angle
    thick_thin = stats.bernoulli.rvs(0.5, size = n_trials) # thick/thin trial
    gabor_freq_cm_vec = 2.38 + 1.2*thick_thin # gabor frequency based on thick/thin trial

    # image folders
    stim_dirs = [stim_dir + "/trial_" + str(i+1) for i in range(n_trials)]

    # magic
    for i in range(n_trials):
        folder = stim_dirs[i]
        try:
            os.mkdir(folder) # make directory for trial stimuli
        except OSError: # if directory already exists, delete all contents
            print('Directory {} alredy exists. Deleting files.'.format(folder))
            for filename in os.listdir(folder):
                file_path = os.path.join(folder, filename)
                try:
                    if os.path.isfile(file_path) or os.path.islink(file_path):
                        os.unlink(file_path)
                    elif os.path.isdir(file_path):
                        shutil.rmtree(file_path)
                except Exception as e:
                    print('Failed to delete %s. Reason: %s' % (file_path, e))

        frames_trial, noise_frames, gabor_frames, ann_frames = single_trial(stim_dir = stim_dirs[i],
                                                                            snr = 1/3,
                                                                            stop_trial = stop_trials[i],
                                                                            only_noise_ms = only_noise_ms_vec[i],
                                                                            SSD_ms = SSD_ms_vec[i],
                                                                            rotation_deg = rotation_deg_vec[i],
                                                                            gabor_freq_cm = gabor_freq_cm_vec[i])

        excel_filepath = stim_dirs[i] + "/trial.xlsx"
        exceler(frames_trial, excel_filepath)

        pd.Series([noise_frames,
                   gabor_frames,
                   ann_frames]).to_excel(stim_dirs[i] + "/event_frames.xlsx", index = False)

        pd.Series([int(stop_trials[i]),
                   rotation_deg_vec[i],
                   thick_thin[i]]).to_excel(stim_dirs[i] + "/parameters.xlsx", index = False)
