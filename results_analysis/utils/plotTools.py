import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import os

def saving_manager(should_save = False, save_path = '', should_show = True):
    if should_save == True:
        saving_directory = os.path.dirname(save_path)
        if not os.path.exists(saving_directory):
            os.makedirs(saving_directory, exist_ok=True)
        plt.savefig(save_path, dpi=300, transparent = True)
    if should_show == True:
        plt.show()
        if should_save == True:
            print(f'Plot saved here: {save_path}')
        else:
            print('Plot not saved. Remember to set should_save to True if you want to save it.')
        plt.close()
    else:
        plt.close()

def darken_color(color, factor=0.8):
    rgb = mcolors.to_rgb(color)
    darkened_rgb = [c * factor for c in rgb]
    return darkened_rgb