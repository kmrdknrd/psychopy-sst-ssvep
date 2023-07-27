from psychopy import visual, event

# create a window
win = visual.Window(size = [1920, 1080], units="pix")

# create a square
square = visual.Rect(win, width=100, height=100, fillColor="white", lineColor="white", pos=[-200, 0])

# create a circle
circle = visual.Circle(win, radius=50, fillColor="white", lineColor="white", pos=[200, 0])

# flicker frequency
square_flicker_freq = 12  # in Hz
circle_flicker_freq = 30  # in Hz
frame_rate = 120  # refresh rate in Hz
square_frames_per_cycle = int(frame_rate / square_flicker_freq)
circle_frames_per_cycle = int(frame_rate / circle_flicker_freq)

# make square and circle flicker at 12 and 30 Hz independently
while True:
    for frameN in range(frame_rate):
        # Draw square
        if (frameN // square_frames_per_cycle) % 2 == 0:
            square.draw()
        # Draw circle
        if (frameN // circle_frames_per_cycle) % 2 == 0:
            circle.draw()
        
        win.flip()

    # check for quit:
    if event.getKeys(keyList=["space"]):
        break

win.close()




