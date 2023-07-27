# Created on 2022/05/19 at 18:18
# Rewritten into Python from Michael Nunez's makenoise.m (2016) script by Konrad Mikalauskas

import numpy as np
import matplotlib.pyplot as plt

def make_noise(radius_cm = 10, num_bands = 2, sd_pass_cm = 20, freq_bands_cm = [1, 5], plot=False):
    
    # change depending on device
    screen_width_px = 1512
    screen_height_px = 982
    diagonal_cm = 36.068

    # pixels per centimeter
    ppcm = np.sqrt(screen_width_px**2 + screen_height_px**2) / diagonal_cm

    # pixelize
    radius = round(radius_cm*ppcm)
    sd_pass = sd_pass_cm/ppcm
    freq_bands = freq_bands_cm/ppcm

    # x and y coords in cm
    image_px = 2*radius
    x_grid = np.empty((image_px,image_px))
    y_grid = np.empty((image_px,image_px))

    index = 0
    for i in np.linspace(-1, 1, image_px+1)[1:]:
        x_grid[:,index] = i
        y_grid[index,:] = i
        index += 1

    # distance of points to center
    radii = np.sqrt(x_grid**2 + y_grid**2)

    # magic
    unfilt_noise = np.random.normal(size = (image_px,image_px))
    fourier_mat = np.fft.fftshift(np.fft.fft2(unfilt_noise - np.mean(unfilt_noise)))

    bandpass = np.zeros((image_px,image_px))
    for i in range(0, num_bands):
        bandpass += np.exp(-((radii - 2*freq_bands[i])**2)/2/sd_pass**2)

    spec_mat = fourier_mat * bandpass
    noise_mat = np.fft.ifft2(np.fft.fftshift(spec_mat) + np.mean(unfilt_noise)).real

    # standardize matrix values to [0.25, 0.75]
    noise_mat = ( (noise_mat-noise_mat.min()) / (noise_mat.max()-noise_mat.min()) ) / 2 + 0.25
    # noise_mat[666,666] = 1
    # noise_mat[666,-666] = 0

    # make the noise matrix circular
    xc = np.empty((image_px,image_px))
    yc = np.empty((image_px,image_px))
    for i in range(0, image_px):
        xc[:,i] = i+1
        yc[i,:] = i+1
    z = np.sqrt((xc-radius)**2 + (yc-radius)**2)
    noise_mat[z > radius] = np.nan

    # plot
    if plot == True:
        plt.figure()
        plt.imshow(noise_mat, cmap = 'gray')
        # plt.show()

    return noise_mat
