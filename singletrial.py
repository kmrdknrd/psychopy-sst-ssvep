import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

from makenoise import makenoise
from makegabor import makegabor
from makeannulus import makeannulus
# from makefixation import makefixation

np.random.seed(1999)
def single_trial(snr = 1, noise_static = False, gabor_static = False, annulus_static = False):
    noise_ratio = 1 / (snr+1)
    signal_ratio = 1 - noise_ratio

    noise_test = makenoise()
    noise_test = (noise_test-0.25) * 2*noise_ratio + 0.5*signal_ratio
    plt.figure()
    plt.imshow(noise_test, vmin = 0, vmax = 1, cmap = 'gray')
    plt.savefig("stimuli/noise_test.png", dpi = 500)

    gabor_test = makegabor()
    gabor_test = gabor_test * signal_ratio * 2
    noise_gabor_test = noise_test + gabor_test
    plt.figure()
    plt.imshow(noise_gabor_test, vmin = 0, vmax = 1, cmap = 'gray')
    plt.savefig("stimuli/noise_gabor_test.png", dpi = 500)

    annulus_test = makeannulus()
    annulus_test = annulus_test * signal_ratio * 2
    noise_gabor_annulus_test = noise_gabor_test + annulus_test
    plt.figure()
    plt.imshow(noise_gabor_annulus_test, vmin = 0, vmax = 1, cmap = 'gray')
    plt.savefig("stimuli/noise_gabor_annulus_test.png", dpi = 500)
