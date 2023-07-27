# Created on 2022/05/26 at 19:04
# Rewritten into Python from Michael Nunez's makegabor.m (2016) script by Konrad Mikalauskas

import numpy as np
import matplotlib.pyplot as plt

def make_gabor(radius_cm = 10, gabor_size_cm = 6, rotation_deg = 45, gabor_freq_cm = 5, plot = False):

    # change depending on device
    screen_width_px = 1512
    screen_height_px = 982
    diagonal_cm = 36.068

    # pixels per centimeter
    ppcm = np.sqrt(screen_width_px**2 + screen_height_px**2) / diagonal_cm

    # pixelize
    radius = round(radius_cm*ppcm)
    gabor_size = round(gabor_size_cm*ppcm)
    gabor_freq = gabor_freq_cm/ppcm

    half_gabor = np.floor(gabor_size/2)

    image_px = 2*radius
    x_grid = np.empty((image_px,image_px))
    y_grid = np.empty((image_px,image_px))

    index = 0
    for i in range(-radius+1, radius+1):
        x_grid[:,index] = i
        y_grid[index,:] = i
        index += 1

    # degrees to radians
    rand_phase_rad = np.random.uniform() * 2 * np.pi
    rotation_rad = rotation_deg*(np.pi/180)

    # rand_place = np.random.randint(1, np.floor((2*radius-gabor_size)/3), 2) * np.array((np.sin(90.*np.random.uniform()), np.sin(90.*np.random.uniform())))
    # rand_dir = 3 - 2*np.random.randint(1, 3, 2)
    # shift = rand_place * rand_dir
    shift = np.array((0,0))

    x_p = x_grid*np.cos(rotation_rad) + y_grid*np.sin(rotation_rad) + shift[0]
    y_p = y_grid*np.cos(rotation_rad) - x_grid*np.sin(rotation_rad) + shift[1]

    gabor_mat = np.exp(-((x_p/(half_gabor/2))**2) - (0.4*(y_p/(half_gabor/2))**2)) * np.sin(2*np.pi*gabor_freq*(x_p) + rand_phase_rad)

    # standardize matrix values to [-1, 1]
    gabor_mat = ( (gabor_mat-gabor_mat.min()) / (gabor_mat.max()-gabor_mat.min()) - 0.5) * 0.5

    # make gabor matrix circular
    xc = np.empty((image_px,image_px))
    yc = np.empty((image_px,image_px))
    for i in range(0, image_px):
        xc[:,i] = i+1
        yc[i,:] = i+1
    z = np.sqrt((xc-radius)**2 + (yc-radius)**2)
    gabor_mat[z > radius] = np.nan

    # plot
    if plot == True:
        plt.figure()
        plt.imshow(gabor_mat, cmap = 'gray')
        # plt.show()

    return gabor_mat
