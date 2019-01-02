# importing stuff
import time
import datetime
import os
import importlib   # for reloading modules
import serial      # for communication with arduino
import collections # for ordered dicts (session_info)
import pysistence  # for immutable dict (mouse_info)
import warnings
import box_utils   # box_utils.py must be in the same folder as this file
import socket
import random


# defining immutable mouse dict (once defined for a mouse, this should never change)
mouse_info = pysistence.make_dict({'mouseName': 'jaxmale08',
                 'requiredVersion': 7,
                 'leftVisCue': 0,
                 'rightVisCue': 3,
                 'leftAudCue': 3,
                 'rightAudCue': 0})

# Information for this session (the user should edit this each session)
session_info                              = collections.OrderedDict()
session_info['mouseName']                 = mouse_info['mouseName']
session_info['trainingPhase']             = 2
session_info['date']                      = datetime.datetime.now().strftime("%Y%m%d")
session_info['time']                      = datetime.datetime.now().strftime('%H%M%S')
session_info['basename']                  = mouse_info['mouseName'] + '_' + session_info['date'] + '_' + session_info['time']
session_info['box_number']                = 1      # put the number of the behavior box here
session_info['computer_name']             = socket.gethostname()

# this applies only for phase 3, where the goal is to get it down to 4000 ms
phase3_go_to_pokes_length                 = 60 * 1000 

# other parameters
session_info['maxSessionLength_min']      = 60     # in minutes
session_info['maxTrials']                 = 3   # program terminates when either maxSessionLength_min or maxTrials is reached
session_info['maxRewards']                = 200    # program also terminates if maxRewards is reached
session_info['interTrialInterval_mean']   = 1      # number of extra seconds between trials
session_info['interTrialInterval_SD']     = 0.5    # standard deviation of seconds between trials
session_info['punishForErrorPokeYN']      = 0      # 0 = no, 1 = yes for stage 5 only
session_info['cueWithdrawalPunishYN']     = 0      # only 1 in phase 4-5
session_info['initPokePunishYN']          = 0      # whether to punish for init poke between trials
nTrial                                    = 1      # the number of the first trial
session_info['nTrial']                    = []     # just leave this blank
session_info['resetTimeYN']               = 1      # whether or not to restart arduino timer at beginning of session

# initializing trial L/R parameters, will set them later
session_info['trialLRtype']               = [] # (1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL).
session_info['trialLRtype_info']          = '(1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL)'
session_info['LrewardCode']               = [] # will be set automatically later
session_info['RrewardCode']               = []

# this is planning for the future, when we will likely want two auditory
# stimuli and two visual stimuli. For now, just leave it as all 3's
session_info['trialAVtype']               = [3]  # 1 = auditory only, 2 = visual only, 3 = both aud + vis
session_info['trialAVtype_info']          = '1 = auditory only, 2 = visual only, 3 = both aud + vis'

# will use this later, when we do optogenetic manipulation
session_info['laserOnCode']            = [0]

# reward parameters for first trial
session_info['LrewardSize_nL']         = [5000] # the starting value, which will be updated over time
session_info['RrewardSize_nL']         = [5000]
session_info['rewardSizeMax_nL']       = [8000]
session_info['rewardSizeMin_nL']       = [2000]
session_info['rewardSizeDelta_nL']     = [500] # the number of nanoliters to adjust reward size by 
session_info['deliveryDuration_ms']    = 1000
session_info['syringeSize_mL']         = 5

# time intervals
session_info['readyToGoLength']        = 1000*30
session_info['punishDelayLength']      = 1000*6
session_info['goToPokesLength']        = 1000*60
session_info['rewardCollectionLength'] = 1000*5

# cue lengths, etc. - for phases 4 and 5, they are changed below
session_info['preCueLength']           = [0]
session_info['cue1Length']             = [100]
session_info['cue2Length']             = [100]
session_info['interOnsetInterval']     = [0]
session_info['postCueLength']          = [0]

# cue volume and brightness
session_info['WNvolume']               = 50     # volumes are 0-255
session_info['lowCueVolume']           = 120
session_info['highCueVolume']          = 120
session_info['buzzerVolume']           = 90
session_info['cueLED1Brightness']      = 1023   # brightness is 0-1023
session_info['cueLED2Brightness']      = 1023
session_info['cueLED3Brightness']      = 1023
session_info['cueLED4Brightness']      = 1023

# setting parameters based on training phase
if session_info['trainingPhase'] == 1:
	session_info['punishForErrorPokeYN']      = 0 # 0 = no, 1 = yes for stage 5 only
	session_info['cueWithdrawalPunishYN']     = 0 # only 1 in phase 4-5
	session_info['goToPokesLength']           = 60 * 1000
elif session_info['trainingPhase'] == 2:
	session_info['punishForErrorPokeYN']      = 0 # 0 = no, 1 = yes for stage 5 only
	session_info['cueWithdrawalPunishYN']     = 0 # only 1 in phase 4-5
	session_info['goToPokesLength']           = 60 * 1000
elif session_info['trainingPhase'] == 3:
	session_info['punishForErrorPokeYN']      = 0 # 0 = no, 1 = yes for stage 5 only
	session_info['cueWithdrawalPunishYN']     = 0 # only 1 in phase 4-5
	session_info['goToPokesLength']           = phase3_go_to_pokes_length
elif session_info['trainingPhase'] == 4:
	session_info['punishForErrorPokeYN']      = 0 # 0 = no, 1 = yes for stage 5 only
	session_info['cueWithdrawalPunishYN']     = 1 # only 1 in phase 4-5
	session_info['goToPokesLength']           = 4 * 1000
elif session_info['trainingPhase'] == 5:
	session_info['punishForErrorPokeYN']      = 1 # 0 = no, 1 = yes for stage 5 only
	session_info['cueWithdrawalPunishYN']     = 1 # only 1 in phase 4-5
	session_info['goToPokesLength']           = 4 * 1000
    
# initializing the cue/slot parameters
session_info['slot1_vis'] = []
session_info['slot1_aud'] = []
session_info['slot2_vis'] = []
session_info['slot2_aud'] = []
session_info['slot3_vis'] = []
session_info['slot3_aud'] = []
session_info['slot1Length'] = []
session_info['slot2Length'] = []
session_info['slot3Length'] = []

# figure out the COM port
basedir  = 'C:\\Users\\lukes\\Desktop\\temp'
COM_port = 'COM5'  # fix: update this later

# make directory to store logfile in
os.chdir(basedir)
if os.path.isdir(session_info['basename']):
    warnings.warn('Data directory with the current date and time already exists. Proceeding anyway...')
else:
    os.mkdir(session_info['basename'])
os.chdir(session_info['basename'])

# making connection with arduino, checking that required version is correct
connection_speed = 115200    # tried 230400, and it didn't work
try:
    del arduino
except:
    pass
arduino = serial.Serial(COM_port, connection_speed, timeout=10) # Establish the connection on a specific port
arduino.set_buffer_size(rx_size=10000000, tx_size=10000000)
time.sleep(1)  # required for connection to complete before transmitting
# arduino.write(b'calibrationLength;1000\n')  # for testing

# verify the arduino is running the correct version of the box code
arduino.flushInput()
arduino.write(bytes('checkVersion', 'utf-8'))
ver = int(arduino.readline())
if ver != mouse_info['requiredVersion']:
    raise Exception('This requires the arduino to run version ' + str(mouse_info['requiredVersion']) + \
                    ', but it is running ver ' + str(ver))
del ver

# initializing default box_params and sending to arduino
box_utils.set_box_defaults(arduino)

# create GUI to ask user to start trial
box_utils.ask_if_ready(session_info)

# launch second GUI to provide buttons to stop the session

# start camera
box_utils.send_dict_to_arduino({'cameraRecordingYN' : 1}, arduino)

# loop over trials begins here
start_time = time.time()
exit_loop = False
while exit_loop == False:
    # setting parameters for this trial

    # setting trial number
    session_info['nTrial'].append(nTrial)

    # for stages 1-2, this should be [1 3]. For stage 3 and higher, it should be [1:6]
    # i.e. no free choice until stage 3
    box_utils.append_random_LR(session_info)

    # set reward codes for the first trial
    box_utils.append_reward_code(session_info)

    # set cue/slot cotes for the first trial
    box_utils.append_cue_codes(session_info, mouse_info)

    # fix: append new reward size here if it's going to 

    # send session_info to arduino
    box_utils.send_dict_to_arduino(session_info, arduino)

    # open log file
    logfile = open(session_info['basename'] + '.txt', 'a+')

    # start the trial
    #arduino.write(bytes('trainingPhase;1', 'utf-8'))
    # flush buffer
    # arduino.flushInput()
    arduino.write(bytes('startTrialYN;1', 'utf-8'))


    # loop to log info from arduino while trial runs
    Astr = str('')  # declare temp string
    while not Astr.endswith('Standby;0'):
      if arduino.in_waiting > 0:
        time.sleep(0.010) # to prevent readline() from being called before the entire string is written
        Astr = arduino.readline().decode('utf-8').rstrip()
        print(Astr)
        logfile.write(Astr + '\n')

      else:
        time.sleep(0.050)

    del Astr
    logfile.close()
    print('Trial completed')
    nTrial += 1

    # evaluate whether or not to exit the loop
    if time.time() - start_time > session_info['maxSessionLength_min']:
        print('Session reached maximum duration. Exiting.')
        exit_loop = True
    elif nTrial > session_info['maxTrials']:
        print('Maximum trial number reached. Exiting.')
        exit_loop = True
#    elif totalRewards > session_info['maxRewards']:  # fix: have to put this in
#        print('Maximum number of rewards reached. Exiting.')
#        exit_loop = True

    # optionally add random extra ITI
    time.sleep(random.gauss(session_info['interTrialInterval_mean'], session_info['interTrialInterval_SD']))


# end of loop



# stop camera
#arduino.write(bytes('cameraRecordingYN;0', 'utf-8'))
box_utils.send_dict_to_arduino({'cameraRecordingYN': 0}, arduino)

# save dicts to disk

# close arduino
time.sleep(1)
arduino.close()