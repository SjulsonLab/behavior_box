import time

import tkinter
from tkinter import *
from tkinter import messagebox

session_info = {}
session_info['mouseName']                 = 'test_mouse'
session_info['trainingPhase']             = 2

root = Tk()
texto = Toplevel(root)

ready_to_go = False
while ready_to_go == False:
    time.sleep(0.1)
    ready_to_go = messagebox.askokcancel(session_info['mouseName'] + ', Phase ' + str(session_info['trainingPhase']), \
                           'Start camera and recordings now, then hit OK to start the trials', default='cancel', parent=texto)
    


