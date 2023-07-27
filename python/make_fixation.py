# Created on 2022/06/08 at 15:19
# Rewritten into Python from Michael Nunez's makefixation.m (2016) script by Konrad Mikalauskas

import numpy as np
import matplotlib.pyplot as plt

def make_fixation(radius_cm = 10, fixation_cm = 0.2, plot = False):

    # change depending on device
    screen_width_px = 1512
    screen_height_px = 982
    diagonal_cm = 36.068

    # pixels per centimeter
    ppcm = np.sqrt(screen_width_px**2 + screen_height_px**2) / diagonal_cm

    # pixelize
    radius = round(radius_cm*ppcm)
    fix = round(fixation_cm*ppcm)

    image_px = 2*radius
    fix_mat = np.zeros((image_px, image_px))

    # make fixation matrix circular
    xc = np.empty((image_px,image_px))
    yc = np.empty((image_px,image_px))
    for i in range(0, image_px):
        xc[:,i] = i+1
        yc[i,:] = i+1
    z = np.sqrt((xc-radius)**2 + (yc-radius)**2)
    fix_mat[z > radius] = np.nan

    # make fixation point
    fix_mat[z < fix] = 

    # plot
    if plot == True:
        plt.figure()
        plt.imshow(fix_mat, cmap = 'gray')
        # plt.show()

    return fix_mat
