# Created on 2022/06/08 at 19:39
# Based on Michael Nunez's makefixation.m (2016) script
# Written by Konrad Mikalauskas (2022)

import numpy as np
import matplotlib.pyplot as plt

def make_annulus(radius_cm = 10, ann_dist_cm = 7, ann_width_cm = 1, alpha = 0.5, plot = False):

    # change depending on device
    screen_width_px = 1512
    screen_height_px = 982
    diagonal_cm = 36.068

    # pixels per centimeter
    ppcm = np.sqrt(screen_width_px**2 + screen_height_px**2) / diagonal_cm

    # pixelize
    radius = round(radius_cm*ppcm)
    ann_dist = round(ann_dist_cm*ppcm)
    ann_width = round(ann_width_cm*ppcm)

    image_px = 2*radius
    ann_mat = np.zeros((image_px, image_px))

    # make annulus 
    xc = np.empty((image_px,image_px))
    yc = np.empty((image_px,image_px))
    for i in range(0, image_px):
        xc[:,i] = i+1
        yc[i,:] = i+1
    z = np.sqrt((xc-radius)**2 + (yc-radius)**2)
    r_half = np.sqrt((2 * ann_dist**2 + ann_width**2 / 2) / 2)

    ann_mat[z > (ann_dist - ann_width/2)] = 0.25
    ann_mat[z > r_half] = -0.25
    ann_mat[z > (ann_dist + ann_width/2)] = 0
    ann_mat[z > radius] = np.nan

    # plot
    if plot == True:
        plt.figure()
        plt.imshow(ann_mat, cmap = 'gray', alpha = alpha)
        # plt.show()

    return ann_mat