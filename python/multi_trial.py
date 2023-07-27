import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy.stats as stats
import os

from single_trial import *


def multi_trial(
    n_trials = 5, stop_trial_prop = 0.2,
    snr_mean = 0.333, snr_sd = 0,
    only_noise_ms_mean = 60, only_noise_ms_sd = 10,
    SSD_ms_mean = 60, SSD_ms_sd = 10,
    stim_dir = "stimuli"
    ):

    stop_trials = stats.bernoulli.rvs(stop_trial_prop, 0, n_trials)
    stop_trials = [bool(i) for i in stop_trial]

    snr_vec = stats.norm.rvs(snr_mean, snr_sd, n_trials)
    only_noise_ms_vec = stats.norm.rvs(only_noise_ms_mean, only_noise_ms_sd, n_trials)
    SSD_ms_vec = stats.norm.rvs(SSD_ms_mean, SSD_ms_sd, n_trials)

    stim_dirs = [stim_dir + "/trial_" + str(i+1) for i in range(n_trials)]

    for i in range(n_trials):
        try:
            os.mkdir(stim_dirs[i])
        except OSError:
            print('Directory {} alredy exists. Files overwritten.'.format(stim_dirs[i]))  

        frames_trial, noise_frames, gabor_frames, ann_frames = single_trial(stim_dir = stim_dirs[i],
                                                                            snr = snr_vec[i],
                                                                            stop_trial = stop_trials[i],
                                                                            only_noise_ms = only_noise_ms_vec[i],
                                                                            SSD_ms = SSD_ms_vec[i])

        excel_filepath = stim_dirs[i] + "/trial.xlsx"
        exceler(frames_trial, excel_filepath)

        event_frames = pd.Series([noise_frames, gabor_frames, ann_frames]).to_excel(stim_dirs[i] + "/event_frames.xlsx")
