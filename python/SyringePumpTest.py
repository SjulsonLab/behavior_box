#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon May 20 17:47:42 2019

@author: elie
"""

import tkinter as tk
import time
import datetime
import os, sys
import importlib   # for reloading modules
import serial      # for communication with arduino
import collections # for ordered dicts (session_info)
import pysistence  # for immutable dict (mouse_info)
import warnings
import box_utils   # box_utils.py must be in the same folder as this file
import socket
import random
import traceback
import colorama
from colorama import Fore, Style
    
#mouse info
mouse_info = pysistence.make_dict({'mouseName': 'testingProtocol',
                 'requiredVersion': 7,
                 'leftVisCue': 0,
                 'rightVisCue': 3,
                 'leftAudCue': 3,
                 'rightAudCue': 0})


#session info
session_info                        = collections.OrderedDict()
session_info['computer_name']       = socket.gethostname()
session_info['box_number']          = 1 

box_utils.set_COM_port(session_info) 

connection_speed = 115200    # tried 230400, and it didn't work
try:
    del arduino
except:
    pass
arduino = serial.Serial(session_info['COM_port'], connection_speed, timeout=10) # Establish the connection on a specific port

if sys.platform == "win32": #the function below doesn't exist for linux. And it is working fine without it.
    arduino.set_buffer_size(rx_size=10000000, tx_size=10000000)

time.sleep(1)  # required for connection to complete before transmitting
# arduino.write(b'calibrationLength;1000\n')  # for testing

# verify the arduino is running the correct version of the box code
arduino.flushInput()
arduino.write(bytes('checkVersion',encoding = 'utf-8'))
ver = int(arduino.readline())
if ver != mouse_info['requiredVersion']:
    raise Exception('This requires the arduino to run version ' + str(mouse_info['requiredVersion']) + \
                    ', but it is running ver ' + str(ver))
del ver


#generating GUI

root = tk.Tk()
frame = tk.Frame(root)
frame.pack()

counterL = tk.IntVar()
counterI = tk.IntVar()
counterR = tk.IntVar()

#defining different functions for different commands so we can call inside the function of each button
def countL():
    counterL.set(counterL.get()+1)

def countI():
    counterI.set(counterI.get()+1)

def countR():
    counterR.set(counterR.get()+1)

def LeftPump():
    arduino.write(bytes( 'activatePump;1',encoding = 'utf-8'))

def InitPump():
    arduino.write(bytes( 'activatePump;2',encoding = 'utf-8'))

def RightPump():
    arduino.write(bytes( 'activatePump;3',encoding = 'utf-8'))

def Activate():
    arduino.write(bytes( 'calibrationLength;1000',encoding = 'utf-8'))

def onClickL(evt = None):
    countL()
    LeftPump()
    time.sleep(0.11)
    Activate()
    
def onClickI(event=None):
    countI()
    InitPump()
    time.sleep(0.11)
    Activate()
    
def onClickR(event=None):
    countR()
    RightPump()
    time.sleep(0.11)
    Activate()
    
def ClickTest(event=None):
    #arduino.write(bytes("1" + ';' + "deliverReward_dc(5000, 1000, 5, 26);" + '\n',encoding = 'utf-8'))
    arduino.write(bytes( 'activatePump;1',encoding = 'utf-8')) #this is working, hooray
    arduino.write(bytes( 'calibrationLength;1000',encoding = 'utf-8')) #this is working, hooray
    
    """now I have to figure out the reward code, I tried sending code to deliver reward, but maybe I have to set up
    the size of syringe, reward size and etc before sending that code"""

button = tk.Button(frame, 
                   text="QUIT", 
                   fg="red",
                   command=quit,
                   padx=50, pady=75)
button.grid(row=0, column=1, padx=10, pady=10)
button.pack(side=tk.LEFT,padx = 30,pady = 100)

#left button
slogan = tk.Label(frame,text="Left clicks: ")
slogan.place(relx=0.32, rely=0.06, anchor='s')
slogan = tk.Label(frame,textvariable=counterL)
slogan.place(relx=0.36, rely=0.06, anchor='s')
slogan = tk.Button(frame,
                   text="Left Syringe Pump",
                   command=onClickL,
                   padx=50, pady=75)
slogan.pack(side=tk.LEFT,padx = 30,pady = 100)

#init button
slogan = tk.Label(frame,text="Init clicks: ")
slogan.place(relx=0.58, rely=0.06, anchor='s')
slogan = tk.Label(frame,textvariable=counterI)
slogan.place(relx=0.61, rely=0.06, anchor='s')
slogan = tk.Button(frame,
                   text="Init Syringe Pump",
                   command=onClickI,
                   padx=50, pady=75)
slogan.pack(side=tk.LEFT,padx = 30,pady = 100)


#right button
slogan = tk.Label(frame,text="Right clicks: ")
slogan.place(relx=0.85, rely=0.06, anchor='s')
slogan = tk.Label(frame,textvariable=counterR)
slogan.place(relx=0.88, rely=0.06, anchor='s')
slogan = tk.Button(frame,
                   text="Right Syringe Pump",
                   command=onClickR,
                   padx=50, pady=75)
slogan.pack(side=tk.LEFT,padx = 30,pady = 100)

root.mainloop()






### testing
#box_utils.send_dict_to_arduino({'LrewardSize_nL' : 5000}, arduino)
#box_utils.send_dict_to_arduino({'giveRewardNow' : 2}, arduino)