from psychopy import visual, event

# create a window
win = visual.Window(size = [1920, 1080], units="pix")

# Don't record frame intervals
win.recordFrameIntervals = False

# create a square
square = visual.Rect(win, width=100, height=100, fillColor="white", lineColor="white")

# flicker frequency
flicker_freq = 12  # in Hz
frame_rate = 120  # refresh rate in Hz
frames_per_cycle = int(frame_rate / flicker_freq)

# flicker loop
while True:
    for frameN in range(frames_per_cycle):
        square.draw()
        win.flip()
    for frameN in range(frames_per_cycle):
        win.flip()

    # check for quit:
    if event.getKeys(keyList=["space"]):
        break

win.close()